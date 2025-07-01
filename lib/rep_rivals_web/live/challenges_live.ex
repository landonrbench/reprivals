defmodule RepRivalsWeb.ChallengesLive do
  use RepRivalsWeb, :live_view

  alias RepRivals.Library
  alias RepRivals.Accounts
  alias RepRivals.Repo

  @impl true
  def mount(_params, _session, socket) do
    user_id = socket.assigns.current_scope.user.id

    # Get all challenge data
    my_challenges = Library.list_challenges_for_user(user_id)
    challenge_invites = Library.list_challenge_invites_for_user(user_id)
    friends = Accounts.list_friends(user_id)

    # Mark all challenge invites as viewed when the page loads
    Enum.each(challenge_invites, fn invite ->
      if is_nil(invite.viewed_at) do
        Library.mark_challenge_viewed(invite)
      end
    end)

    # Get workouts for the create modal
    workouts = Library.list_workouts_for_user(user_id)

    socket =
      socket
      |> assign(:my_challenges, my_challenges)
      |> assign(:challenge_invites, challenge_invites)
      |> assign(:friends, friends)
      |> assign(:active_tab, "my_challenges")
      |> assign(:show_create_modal, false)
      |> assign(:selected_workout, nil)
      |> assign(:selected_friends, [])
      |> assign(:challenge_form, to_form(%{}))
      |> assign(:workouts, workouts)
      |> assign(:workout_search, "")

    {:ok, socket}
  end

  @impl true
  def handle_event("switch_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, :active_tab, tab)}
  end

  @impl true
  def handle_event("show_create_modal", _params, socket) do
    IO.puts("DEBUG: show_create_modal event received")
    user_id = socket.assigns.current_scope.user.id
    workouts = Library.list_workouts_for_user(user_id)

    {:noreply,
     socket
     |> assign(:show_create_modal, true)
     |> assign(:workouts, workouts)
     |> assign(:workout_search, "")}
  end

  @impl true
  def handle_event("search_workouts", %{"value" => search_term}, socket) do
    user_id = socket.assigns.current_scope.user.id
    filtered_workouts = Library.search_workouts_for_user(user_id, search_term)

    {:noreply,
     socket
     |> assign(:workouts, filtered_workouts)
     |> assign(:workout_search, search_term)}
  end

  def handle_event("hide_create_modal", _params, socket) do
    {:noreply,
     socket
     |> assign(:show_create_modal, false)
     |> assign(:selected_workout, nil)
     |> assign(:selected_friends, [])
     |> assign(:challenge_form, to_form(%{}))}
  end

  @impl true
  def handle_event("select_workout", %{"workout_id" => workout_id}, socket) do
    workout = Library.get_workout!(workout_id)
    challenge_form = to_form(%{"name" => "#{workout.name} Challenge"})

    {:noreply,
     socket
     |> assign(:selected_workout, workout)
     |> assign(:challenge_form, challenge_form)}
  end

  @impl true
  def handle_event("toggle_friend", %{"friend_id" => friend_id}, socket) do
    friend_id = String.to_integer(friend_id)
    selected_friends = socket.assigns.selected_friends

    updated_friends =
      if friend_id in selected_friends do
        List.delete(selected_friends, friend_id)
      else
        [friend_id | selected_friends]
      end

    {:noreply, assign(socket, :selected_friends, updated_friends)}
  end

  @impl true
  def handle_event("create_challenge", challenge_params, socket) do
    user_id = socket.assigns.current_scope.user.id
    selected_workout = socket.assigns.selected_workout
    selected_friends = socket.assigns.selected_friends

    if selected_workout && length(selected_friends) > 0 do
      challenge_attrs = %{
        name: challenge_params["name"],
        description: challenge_params["description"] || "",
        creator_id: user_id,
        workout_id: selected_workout.id,
        status: "active"
      }

      case Library.create_challenge(challenge_attrs) do
        {:ok, challenge} ->
          IO.puts("DEBUG: Challenge creation successful, challenge ID: #{challenge.id}")
          IO.puts("DEBUG: Selected friends for participants: #{inspect(selected_friends)}")

          case Library.create_challenge_participants(challenge.id, selected_friends) do
            {:ok, participants} ->
              IO.puts("DEBUG: Participants created successfully: #{inspect(participants)}")
              # Refresh data
              my_challenges = Library.list_challenges_for_user(user_id)

              {:noreply,
               socket
               |> assign(:my_challenges, my_challenges)
               |> assign(:show_create_modal, false)
               |> assign(:selected_workout, nil)
               |> assign(:selected_friends, [])
               |> assign(:challenge_form, to_form(%{}))
               |> put_flash(:info, "Challenge created successfully!")}

            {:error, error} ->
              IO.puts("DEBUG: Failed to create participants, error: #{inspect(error)}")
              {:noreply, put_flash(socket, :error, "Failed to invite participants")}
          end

        {:error, changeset} ->
          IO.puts("DEBUG: Failed to create challenge, changeset: #{inspect(changeset)}")
          {:noreply, put_flash(socket, :error, "Failed to create challenge")}
      end
    else
      {:noreply, put_flash(socket, :error, "Please select a workout and at least one friend")}
    end
  end

  @impl true
  def handle_event("accept_challenge", %{"participant_id" => participant_id}, socket) do
    participant = Repo.get!(Library.ChallengeParticipant, participant_id)

    case Library.update_challenge_participant(participant, %{status: "accepted"}) do
      {:ok, _updated_participant} ->
        user_id = socket.assigns.current_scope.user.id
        challenge_invites = Library.list_challenge_invites_for_user(user_id)

        {:noreply,
         socket
         |> assign(:challenge_invites, challenge_invites)
         |> put_flash(:info, "Challenge accepted!")}

      {:error, _changeset} ->
        IO.puts("DEBUG: Failed to accept challenge")
        {:noreply, put_flash(socket, :error, "Failed to accept challenge")}
    end
  end

  @impl true
  def handle_event(
        "complete_challenge",
        %{
          "participant_id" => participant_id,
          "result_value" => result_value,
          "result_unit" => result_unit,
          "result_notes" => result_notes
        },
        socket
      ) do
    participant = Library.get_challenge_participant!(participant_id)

    if participant.user_id == socket.assigns.current_scope.user.id do
      case Library.update_challenge_participant(participant, %{
             status: "completed",
             result_value: result_value,
             result_unit: result_unit,
             result_notes: result_notes,
             completed_at: DateTime.utc_now()
           }) do
        {:ok, _updated_participant} ->
          # Broadcast update to all participants
          Phoenix.PubSub.broadcast(
            RepRivals.PubSub,
            "challenge_#{participant.challenge_id}",
            :challenge_updated
          )

          {:noreply,
           socket
           |> put_flash(:info, "Challenge completed successfully!")
           |> load_challenge_data()}

        {:error, _changeset} ->
          {:noreply, put_flash(socket, :error, "Could not complete challenge")}
      end
    else
      {:noreply, put_flash(socket, :error, "Unauthorized")}
    end
  end

  def handle_event("show_complete_form", %{"participant_id" => participant_id}, socket) do
    {:noreply, assign(socket, :completing_participant_id, participant_id)}
  end

  def handle_event("hide_complete_form", _params, socket) do
    {:noreply, assign(socket, :completing_participant_id, nil)}
  end

  @impl true
  def handle_event("decline_challenge", %{"participant_id" => participant_id}, socket) do
    participant = Repo.get!(Library.ChallengeParticipant, participant_id)

    case Library.update_challenge_participant(participant, %{status: "declined"}) do
      {:ok, _updated_participant} ->
        user_id = socket.assigns.current_scope.user.id
        challenge_invites = Library.list_challenge_invites_for_user(user_id)

        {:noreply,
         socket
         |> assign(:challenge_invites, challenge_invites)
         |> put_flash(:info, "Challenge declined")}

      {:error, _changeset} ->
        IO.puts("DEBUG: Failed to decline challenge")
        {:noreply, put_flash(socket, :error, "Failed to decline challenge")}
    end
  end

  defp format_date(datetime) do
    Calendar.strftime(datetime, "%b %d")
  end

  defp get_challenge_status(challenge) do
    total_participants = length(challenge.participants)
    completed_participants = Enum.count(challenge.participants, &(&1.status == "completed"))

    cond do
      completed_participants == 0 ->
        "⏳ Pending"

      completed_participants < total_participants ->
        "🟡 #{completed_participants}/#{total_participants} Done"

      true ->
        "✅ Complete"
    end
  end

  defp get_participant_status(participant) do
    case participant.status do
      "invited" -> "⏳ Invited"
      "accepted" -> "🟡 Accepted"
      "completed" -> "✅ Complete"
      "declined" -> "❌ Declined"
    end
  end

  defp load_challenge_data(socket) do\
    user_id = socket.assigns.current_scope.user.id\
    my_challenges = Library.list_challenges_for_user(user_id)\
    challenge_invites = Library.list_challenge_invites_for_user(user_id)\
    \
    socket\
    |> assign(:my_challenges, my_challenges)\
    |> assign(:challenge_invites, challenge_invites)\
  end
  defp friend_selected?(friend_id, selected_friends) do
    friend_id in selected_friends
  end
end
