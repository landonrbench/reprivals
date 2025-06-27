defmodule RepRivalsWeb.WorkoutDetailLive do
  use RepRivalsWeb, :live_view

  alias RepRivals.Library
  alias RepRivals.Library.WorkoutResult

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    workout = Library.get_workout!(id)
    workout_results = Library.list_workout_results(id)

    if connected?(socket) do
      Phoenix.PubSub.subscribe(RepRivals.PubSub, "workout_results:#{id}")
    end

    {:ok,
     socket
     |> assign(:page_title, workout.name)
     |> assign(:workout, workout)
     |> assign(:workout_results, workout_results)
     |> assign(:show_log_form, false)
     |> assign(:show_edit_modal, false)
     |> assign(:show_delete_modal, false)
     |> assign(:form, to_form(Library.change_workout_result(%WorkoutResult{})))
     |> assign(:edit_form, to_form(Library.change_workout(workout)))}
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
         |> put_flash(:info, "Result logged successfully!")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  @impl true
  def handle_event("show_edit_modal", _params, socket) do
    {:noreply, assign(socket, show_edit_modal: true)}
  end

  @impl true
  def handle_event("hide_edit_modal", _params, socket) do
    {:noreply, assign(socket, show_edit_modal: false)}
  end

  @impl true
  def handle_event("update_workout", %{"workout" => workout_params}, socket) do
    case Library.update_workout(socket.assigns.workout, workout_params) do
      {:ok, updated_workout} ->
        {:noreply,
         socket
         |> assign(:workout, updated_workout)
         |> assign(show_edit_modal: false)
         |> put_flash(:info, "Workout updated successfully!")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, edit_form: to_form(changeset))}
    end
  end

  @impl true
  def handle_event("show_delete_modal", _params, socket) do
    {:noreply, assign(socket, show_delete_modal: true)}
  end

  @impl true
  def handle_event("hide_delete_modal", _params, socket) do
    {:noreply, assign(socket, show_delete_modal: false)}
  end

  @impl true
  def handle_event("delete_workout", _params, socket) do
    case Library.delete_workout(socket.assigns.workout) do
      {:ok, _workout} ->
        {:noreply,
         socket
         |> put_flash(:info, "Workout deleted successfully!")
         |> push_navigate(to: ~p"/")}

      {:error, _changeset} ->
        {:noreply,
         socket
         |> assign(show_delete_modal: false)
         |> put_flash(:error, "Failed to delete workout")}
    end
  end

  @impl true
  def handle_event("back", _params, socket) do
    {:noreply, push_navigate(socket, to: ~p"/")}
  end

  @impl true
  def handle_info({:workout_result_created, workout_result}, socket) do
    updated_results = [workout_result | socket.assigns.workout_results]
    {:noreply, assign(socket, :workout_results, updated_results)}
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
        value: parse_result_value(result.result_value)
      }
    end)
    |> Jason.encode!()
  end

  defp parse_result_value(value) do
    cond do
      # Time format (8:45 or 12:34:56) - convert to seconds
      String.contains?(value, ":") ->
        parts = String.split(value, ":")

        case length(parts) do
          # MM:SS
          2 ->
            [min, sec] = Enum.map(parts, &String.to_integer/1)
            min * 60 + sec

          # HH:MM:SS
          3 ->
            [hour, min, sec] = Enum.map(parts, &String.to_integer/1)
            hour * 3600 + min * 60 + sec

          _ ->
            0
        end

      # Weight or reps - extract number
      true ->
        case Regex.run(~r/(\d+(?:\.\d+)?)/, value) do
          [_, number] -> String.to_float(number)
          _ -> 0
        end
    end
  rescue
    _ -> 0
  end
end
