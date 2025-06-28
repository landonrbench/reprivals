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

    {:ok, socket}
  end

  @impl true
  def handle_event("switch_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, :active_tab, tab)}
  end

  @impl true
  def handle_event("show_create_modal", _params, socket) do
    user_id = socket.assigns.current_scope.user.id
    workouts = Library.list_workouts_for_user(user_id)

    {:noreply,
     socket
     |> assign(:show_create_modal, true)
     |> assign(:workouts, workouts)}
  end

  @impl true
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
          # Add participants
          case Library.create_challenge_participants(challenge.id, selected_friends) do
            {:ok, _participants} ->
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

            {:error, _error} ->
              {:noreply, put_flash(socket, :error, "Failed to invite participants")}
          end

        {:error, _changeset} ->
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
        {:noreply, put_flash(socket, :error, "Failed to accept challenge")}
    end
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

  defp friend_selected?(friend_id, selected_friends) do
    friend_id in selected_friends
  end
end
