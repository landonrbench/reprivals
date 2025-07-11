defmodule RepRivalsWeb.WorkoutDetailLive do
  use RepRivalsWeb, :live_view

  alias RepRivals.Library
  alias RepRivals.Library.WorkoutResult
  alias RepRivals.Accounts

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    workout = Library.get_workout!(id)
    workout_results = Library.list_workout_results(id)
    users = Accounts.list_users()

    if connected?(socket) do
      Phoenix.PubSub.subscribe(RepRivals.PubSub, "workout_results:#{id}")
    end

    {:ok,
     socket
     |> assign(:page_title, workout.name)
     |> assign(:workout, workout)
     |> assign(:workout_results, workout_results)
     |> assign(:users, users)
     |> assign(:show_log_form, false)
     |> assign(:show_edit_modal, false)
     |> assign(:show_delete_modal, false)
     |> assign(:show_edit_result_form, false)
     |> assign(:show_delete_result_modal, false)
     |> assign(:show_challenge_modal, false)
     |> assign(:show_challenge_friends_modal, false)
     |> assign(:current_result, nil)
     |> assign(:challenge_result, nil)
     |> assign(:selected_participant_ids, [])
     |> assign(:available_friends, [])
     |> assign(:selected_challenge_friends, [])
     |> assign(:form, to_form(Library.change_workout_result(%WorkoutResult{})))
     |> assign(:edit_form, to_form(Library.change_workout(workout)))
     |> assign(:edit_result_form, to_form(Library.change_workout_result(%WorkoutResult{})))
     |> assign(:challenge_form, to_form(%{}))}
  end

  @impl true
  def handle_event("back", _params, socket) do
    {:noreply, push_navigate(socket, to: ~p"/notebook")}
  end

  @impl true
  def handle_event("show_log_form", _params, socket) do
    # Set default date to today
    today = Date.utc_today()

    changeset =
      Library.change_workout_result(%WorkoutResult{logged_at: DateTime.new!(today, ~T[12:00:00])})

    {:noreply, assign(socket, show_log_form: true, form: to_form(changeset))}
  end

  @impl true
  def handle_event("hide_log_form", _params, socket) do
    {:noreply, assign(socket, show_log_form: false)}
  end

  def handle_event("validate", %{"workout_result" => result_params}, socket) do
    changeset = Library.change_workout_result(%WorkoutResult{}, result_params)
    changeset =
      case Ecto.Changeset.apply_action(changeset, :validate) do
        {:ok, changes} ->
          Library.change_workout_result(changes)

        {:error, changeset} ->
          changeset
      end
    {:noreply, assign(socket, :form, to_form(changeset))}
  end

  @impl true
  def handle_event("log_result", %{"workout_result" => result_params}, socket) do
    workout = socket.assigns.workout
    user_id = socket.assigns.current_scope.user.id

    # Parse the date and set it as the logged_at datetime
    logged_at =
      case result_params["logged_at"] do
        date_string when is_binary(date_string) and date_string != "" ->
          case Date.from_iso8601(date_string) do
            {:ok, date} -> DateTime.new!(date, ~T[12:00:00])
            _ -> DateTime.utc_now()
          end

        _ ->
          DateTime.utc_now()
      end

    result_params =
      result_params
      |> Map.put("workout_id", workout.id)
      |> Map.put("user_id", user_id)
      |> Map.put("logged_at", logged_at)

    case Library.create_workout_result(result_params) do
      {:ok, _workout_result} ->
        {:noreply,
         socket
         |> assign(show_log_form: false)
         |> assign(:workout_results, Library.list_workout_results(workout.id))
         |> put_flash(:info, "Result logged successfully!")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  @impl true
  def handle_event("log_result_and_challenge", _params, socket) do
    workout = socket.assigns.workout
    user_id = socket.assigns.current_scope.user.id
    form = socket.assigns.form

    # Get form params from the changeset
    form_params = form.params || %{}

    # Parse the date and set it as the logged_at datetime
    logged_at =
      case Map.get(form_params, "logged_at") do
        date_string when is_binary(date_string) and date_string != "" ->
          case Date.from_iso8601(date_string) do
            {:ok, date} -> DateTime.new!(date, ~T[12:00:00])
            _ -> DateTime.utc_now()
          end

        _ ->
          DateTime.utc_now()
      end

    result_params = %{
      "workout_id" => workout.id,
      "user_id" => user_id,
      "result_value" => Map.get(form_params, "result_value", ""),
      "notes" => Map.get(form_params, "notes", ""),
      "logged_at" => logged_at
    }

    case Library.create_workout_result(result_params) do
      {:ok, workout_result} ->
        # Get available friends (all users except current user)
        available_friends = Enum.reject(socket.assigns.users, &(&1.id == user_id))

        {:noreply,
         socket
         |> assign(show_log_form: false)
         |> assign(show_challenge_friends_modal: true)
         |> assign(available_friends: available_friends)
         |> assign(selected_challenge_friends: [])
         |> assign(challenge_form: to_form(%{"name" => "", "description" => ""}))
         |> assign(challenge_result: workout_result)
         |> put_flash(:info, "Result logged! Now create a challenge for your friends.")}

      {:error, changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  @impl true
  def handle_event("hide_challenge_friends_modal", _params, socket) do
    {:noreply,
     socket
     |> assign(show_challenge_friends_modal: false)
     |> assign(available_friends: [])
     |> assign(selected_challenge_friends: [])
     |> assign(challenge_result: nil)}
  end

  @impl true
  def handle_event("toggle_challenge_friend", %{"id" => friend_id}, socket) do
    friend_id = String.to_integer(friend_id)
    current_selected = socket.assigns.selected_challenge_friends

    updated_selected =
      if friend_id in current_selected do
        List.delete(current_selected, friend_id)
      else
        [friend_id | current_selected]
      end

    {:noreply, assign(socket, selected_challenge_friends: updated_selected)}
  end

  @impl true
  def handle_event(
        "create_challenge_with_result",
        %{"name" => name, "description" => description},
        socket
      ) do
    workout = socket.assigns.workout
    user_id = socket.assigns.current_scope.user.id
    selected_friends = socket.assigns.selected_challenge_friends

    challenge_attrs = %{
      name: name,
      description: description,
      status: "active",
      creator_id: user_id,
      workout_id: workout.id
    }

    case Library.create_group_challenge(challenge_attrs, selected_friends) do
      {:ok, _challenge} ->
        {:noreply,
         socket
         |> assign(show_challenge_friends_modal: false)
         |> assign(available_friends: [])
         |> assign(selected_challenge_friends: [])
         |> assign(challenge_result: nil)
         |> put_flash(:info, "Challenge created and friends invited!")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to create challenge")}
    end
  end

  @impl true
  def handle_event("edit_result", %{"id" => result_id}, socket) do
    result = Enum.find(socket.assigns.workout_results, &(&1.id == String.to_integer(result_id)))

    if result do
      # Convert logged_at DateTime to date string for the form
      date_string = result.logged_at |> DateTime.to_date() |> Date.to_string()

      changeset =
        result
        |> Library.change_workout_result(%{logged_at: date_string})

      {:noreply,
       socket
       |> assign(:current_result, result)
       |> assign(:show_edit_result_form, true)
       |> assign(:edit_result_form, to_form(changeset))}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("hide_edit_result_form", _params, socket) do
    {:noreply,
     socket
     |> assign(:show_edit_result_form, false)
     |> assign(:current_result, nil)}
  end

  @impl true
  def handle_event("update_result", %{"workout_result" => result_params}, socket) do
    current_result = socket.assigns.current_result

    # Parse the date and set it as the logged_at datetime
    logged_at =
      case result_params["logged_at"] do
        date_string when is_binary(date_string) and date_string != "" ->
          case Date.from_iso8601(date_string) do
            {:ok, date} -> DateTime.new!(date, ~T[12:00:00])
            _ -> current_result.logged_at
          end

        _ ->
          current_result.logged_at
      end

    result_params = Map.put(result_params, "logged_at", logged_at)

    case Library.update_workout_result(current_result, result_params) do
      {:ok, updated_result} ->
        # Update the results list
        updated_results =
          Enum.map(socket.assigns.workout_results, fn result ->
            if result.id == updated_result.id, do: updated_result, else: result
          end)

        {:noreply,
         socket
         |> assign(:workout_results, updated_results)
         |> assign(:show_edit_result_form, false)
         |> assign(:current_result, nil)
         |> put_flash(:info, "Result updated successfully!")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, edit_result_form: to_form(changeset))}
    end
  end

  @impl true
  def handle_event("show_delete_result_modal", _params, socket) do
    {:noreply, assign(socket, show_delete_result_modal: true)}
  end

  @impl true
  def handle_event("hide_delete_result_modal", _params, socket) do
    {:noreply, assign(socket, show_delete_result_modal: false)}
  end

  @impl true
  def handle_event("delete_result", _params, socket) do
    current_result = socket.assigns.current_result

    case Library.delete_workout_result(current_result) do
      {:ok, _deleted_result} ->
        # Remove the result from the list
        updated_results =
          Enum.reject(socket.assigns.workout_results, &(&1.id == current_result.id))

        {:noreply,
         socket
         |> assign(:workout_results, updated_results)
         |> assign(:show_edit_result_form, false)
         |> assign(:show_delete_result_modal, false)
         |> assign(:current_result, nil)
         |> put_flash(:info, "Result deleted successfully!")}

      {:error, _changeset} ->
        {:noreply,
         socket
         |> assign(:show_delete_result_modal, false)
         |> put_flash(:error, "Failed to delete result")}
    end
  end

  @impl true
  def handle_event("challenge_friends", %{"result_id" => result_id}, socket) do
    result = Enum.find(socket.assigns.workout_results, &(&1.id == String.to_integer(result_id)))

    if result do
      {:noreply,
       socket
       |> assign(:show_challenge_modal, true)
       |> assign(:challenge_result, result)
       |> assign(:selected_participant_ids, [])}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("hide_challenge_modal", _params, socket) do
    {:noreply,
     socket
     |> assign(:show_challenge_modal, false)
     |> assign(:challenge_result, nil)
     |> assign(:selected_participant_ids, [])}
  end

  @impl true
  def handle_event("toggle_participant", %{"user_id" => user_id}, socket) do
    user_id = String.to_integer(user_id)
    current_ids = socket.assigns.selected_participant_ids

    updated_ids =
      if user_id in current_ids do
        List.delete(current_ids, user_id)
      else
        [user_id | current_ids]
      end

    {:noreply, assign(socket, :selected_participant_ids, updated_ids)}
  end

  @impl true
  def handle_event("create_challenge_from_result", _params, socket) do
    challenge_result = socket.assigns.challenge_result
    participant_ids = socket.assigns.selected_participant_ids

    case Library.create_challenge_from_result(challenge_result, participant_ids) do
      {:ok, _challenge} ->
        {:noreply,
         socket
         |> assign(:show_challenge_modal, false)
         |> assign(:challenge_result, nil)
         |> assign(:selected_participant_ids, [])
         |> put_flash(:info, "Challenge created and friends invited!")}

      {:error, _reason} ->
        {:noreply, put_flash(socket, :error, "Failed to create challenge")}
    end
  end

  defp get_log_button_text(metric) do
    case metric do
      "For Time" -> "Log New Time"
      "For Reps" -> "Log New Reps"
      "Weight" -> "Log New Weight"
      _ -> "Log Result"
    end
  end

  defp get_result_placeholder(metric) do
    case metric do
      "For Time" -> "8:45 or 12:34:56"
      "For Reps" -> "150 or 50 reps"
      "Weight" -> "225 or 185 lbs"
      _ -> "Enter result"
    end
  end

  defp format_result_date(datetime) do
    Calendar.strftime(datetime, "%b %d, %Y")
  end

  defp get_chart_data(results) do
    results
    |> Enum.reverse()
    |> Enum.map(fn result ->
      %{
        date: format_result_date(result.logged_at),
        value: result.result_value
      }
    end)
    |> Jason.encode!()
  end

  defp user_is_selected?(user_id, selected_ids) do
    user_id in selected_ids
  end

  defp friend_selected_for_challenge?(friend_id, selected_friends) do
    friend_id in selected_friends
  end
end
