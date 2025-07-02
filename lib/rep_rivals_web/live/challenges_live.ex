defmodule RepRivalsWeb.ChallengesLive do
  use RepRivalsWeb, :live_view

  alias RepRivals.Library
  alias RepRivals.Library.{Challenge, ChallengeParticipant}
  alias RepRivals.Accounts

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(RepRivals.PubSub, "challenges")
    end

    socket =
      socket
      |> assign(:active_tab, "my_challenges")
      |> assign(:show_create_modal, false)
      |> assign(:show_complete_modal, false)
      |> assign(:selected_participant, nil)
      |> assign(:create_form, to_form(%{}))
      |> assign(:complete_form, to_form(%{}))
      |> assign(:selected_workout, nil)
      |> assign(:selected_friends, [])
      |> assign(:search_query, "")
      |> load_challenges()
      |> load_challenge_invites()

    {:ok, socket}
  end

  @impl true
  def handle_params(_params, _uri, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("switch_tab", %{"tab" => tab}, socket) do
    socket =
      socket
      |> assign(:active_tab, tab)
      |> load_challenges()
      |> load_challenge_invites()

    {:noreply, socket}
  end

  def handle_event("show_create_modal", _params, socket) do
    IO.puts("DEBUG: show_create_modal event triggered")
    workouts = Library.list_workouts_for_user(socket.assigns.current_scope.user.id)
    IO.puts("DEBUG: Found #{length(workouts)} workouts")
    friends = Accounts.list_users()
    IO.puts("DEBUG: Found #{length(friends)} total users")
    filtered_friends = Enum.reject(friends, &(&1.id == socket.assigns.current_scope.user.id))
    IO.puts("DEBUG: Filtered to #{length(filtered_friends)} friends")

    {:noreply,
     assign(socket,
       show_create_modal: true,
       workouts: workouts,
       available_friends: filtered_friends,
       selected_workout: nil,
       selected_friends: [],
       search_query: ""
     )}
  end

  def handle_event("close_create_modal", _params, socket) do
    {:noreply,
     assign(socket,
       show_create_modal: false,
       selected_workout: nil,
       selected_friends: [],
       search_query: ""
     )}
  end

  def handle_event("select_workout", %{"id" => workout_id}, socket) do
    workout = Library.get_workout!(workout_id)
    {:noreply, assign(socket, selected_workout: workout)}
  end

  def handle_event("toggle_friend", %{"id" => friend_id}, socket) do
    friend_id = String.to_integer(friend_id)
    current_selected = socket.assigns.selected_friends

    updated_selected =
      if friend_id in current_selected do
        List.delete(current_selected, friend_id)
      else
        [friend_id | current_selected]
      end

    {:noreply, assign(socket, selected_friends: updated_selected)}
  end

  def handle_event("search_workouts", %{"search" => query}, socket) do
    workouts = Library.search_workouts_for_user(socket.assigns.current_scope.user.id, query)
    {:noreply, assign(socket, workouts: workouts, search_query: query)}
  end

  def handle_event("create_challenge", %{"challenge" => challenge_params}, socket) do
    challenge_attrs = %{
      name: challenge_params["name"],
      description: challenge_params["description"],
      status: "active",
      creator_id: socket.assigns.current_scope.user.id,
      workout_id: socket.assigns.selected_workout.id
    }

    case Library.create_group_challenge(challenge_attrs, socket.assigns.selected_friends) do
      {:ok, _challenge} ->
        {:noreply,
         socket
         |> assign(show_create_modal: false, selected_workout: nil, selected_friends: [])
         |> put_flash(:info, "Challenge created successfully!")
         |> load_challenges()}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to create challenge")}
    end
  end

  def handle_event("accept_challenge", %{"id" => participant_id}, socket) do
    participant = Library.get_challenge_participant!(participant_id)

    case Library.update_challenge_participant(participant, %{status: "accepted"}) do
      {:ok, _updated_participant} ->
        # Mark as viewed when accepting
        Library.mark_challenge_viewed(participant)

        {:noreply,
         socket
         |> put_flash(:info, "Challenge accepted!")
         |> load_challenge_invites()}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to accept challenge")}
    end
  end

  def handle_event("decline_challenge", %{"id" => participant_id}, socket) do
    participant = Library.get_challenge_participant!(participant_id)

    case Library.update_challenge_participant(participant, %{status: "declined"}) do
      {:ok, _updated_participant} ->
        # Mark as viewed when declining
        Library.mark_challenge_viewed(participant)

        {:noreply,
         socket
         |> put_flash(:info, "Challenge declined")
         |> load_challenge_invites()}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to decline challenge")}
    end
  end

  def handle_event("show_complete_modal", %{"id" => participant_id}, socket) do
    participant = Library.get_challenge_participant!(participant_id)
    participant = RepRivals.Repo.preload(participant, challenge: [:workout])

    # Create appropriate form based on workout metric
    form_params =
      case participant.challenge.workout.metric do
        "For Time" -> %{"time_minutes" => "", "time_seconds" => ""}
        "For Reps" -> %{"result_value" => ""}
        "Weight" -> %{"result_value" => ""}
      end

    {:noreply,
     assign(socket,
       show_complete_modal: true,
       selected_participant: participant,
       complete_form: to_form(form_params)
     )}
  end

  def handle_event("close_complete_modal", _params, socket) do
    {:noreply,
     assign(socket,
       show_complete_modal: false,
       selected_participant: nil,
       complete_form: to_form(%{})
     )}
  end

  def handle_event("complete_challenge", params, socket) do
    participant = socket.assigns.selected_participant
    workout_metric = participant.challenge.workout.metric

    # Process result based on workout type
    {result_value, result_unit} =
      case workout_metric do
        "For Time" ->
          minutes = String.to_integer(params["time_minutes"] || "0")
          seconds = String.to_integer(params["time_seconds"] || "0")
          total_seconds = minutes * 60 + seconds
          {Decimal.new(total_seconds), "seconds"}

        "For Reps" ->
          reps = String.to_integer(params["result_value"] || "0")
          {Decimal.new(reps), "reps"}

        "Weight" ->
          weight = String.to_integer(params["result_value"] || "0")
          {Decimal.new(weight), "lbs"}
      end

    result_attrs = %{
      status: "completed",
      result_value: result_value,
      result_unit: result_unit,
      result_notes: params["result_notes"],
      completed_at: NaiveDateTime.utc_now()
    }

    case Library.update_challenge_participant(participant, result_attrs) do
      {:ok, _updated_participant} ->
        {:noreply,
         socket
         |> assign(show_complete_modal: false, selected_participant: nil)
         |> put_flash(:info, "Challenge completed!")
         |> check_and_complete_challenge(participant.challenge_id)
         |> load_challenge_invites()}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to complete challenge")}
    end
  end

  # PubSub message handlers
  @impl true
  def handle_info({:challenge_created, _challenge}, socket) do
    {:noreply, load_challenges(socket)}
  end

  def handle_info({:participants_invited, _participants}, socket) do
    {:noreply, load_challenge_invites(socket)}
  end

  def handle_info({:participant_updated, _participant}, socket) do
    socket =
      socket
      |> load_challenges()
      |> load_challenge_invites()

    {:noreply, socket}
  end

  def handle_info(_msg, socket) do
    {:noreply, socket}
  end

  # Helper functions
  defp load_challenges(socket) do
    challenges = Library.list_challenges_for_user(socket.assigns.current_scope.user.id)
    assign(socket, :challenges, challenges)
  end

  defp load_challenge_invites(socket) do
    invites = Library.list_challenge_invites_for_user(socket.assigns.current_scope.user.id)
    assign(socket, :challenge_invites, invites)
  end

  defp challenge_status_class(status) do
    case status do
      "invited" -> "bg-blue-100 text-blue-800"
      "accepted" -> "bg-green-100 text-green-800"
      "declined" -> "bg-red-100 text-red-800"
      "completed" -> "bg-purple-100 text-purple-800"
      _ -> "bg-gray-100 text-gray-800"
    end
  end

  defp challenge_status_text(status) do
    case status do
      "invited" -> "⏳ Invited"
      "accepted" -> "✅ Accepted"
      "declined" -> "❌ Declined"
      "completed" -> "🏆 Completed"
      _ -> status
    end
  end

  defp workout_metric_description(metric) do
    case metric do
      "For Time" -> "Complete as fast as possible"
      "For Reps" -> "Complete as many rounds/reps as possible"
      "Weight" -> "Lift the maximum weight possible"
      _ -> metric
    end
  end

  defp format_result_with_unit(result_value, result_unit) when is_nil(result_value) do
    "No result"
  end

  defp format_result_with_unit(result_value, "seconds") do
    total_seconds = Decimal.to_integer(result_value)
    minutes = div(total_seconds, 60)
    seconds = rem(total_seconds, 60)
    "#{minutes}:#{String.pad_leading(Integer.to_string(seconds), 2, "0")}"
  end

  defp format_result_with_unit(result_value, "reps") do
    "#{Decimal.to_integer(result_value)} reps"
  end

  defp format_result_with_unit(result_value, "lbs") do
    "#{Decimal.to_integer(result_value)} lbs"
  end

  defp format_result_with_unit(result_value, result_unit) do
    "#{result_value} #{result_unit}"
  end

  defp friend_selected?(friend_id, selected_friends) do
    friend_id in selected_friends
  end

  defp form_valid?(selected_workout, selected_friends) do
    selected_workout && selected_friends != []
  end

  defp format_date(date) when is_nil(date), do: "Not set"

  defp check_and_complete_challenge(socket, challenge_id) do\
    challenge = Library.get_challenge!(challenge_id)\
    participants = Library.list_challenge_participants(challenge_id)\
    \
    # Check if all participants have completed the challenge\
    all_completed = Enum.all?(participants, fn participant ->\
      participant.status == "completed"\
    end)\
    \
    if all_completed and challenge.status == "active" do\
      case Library.update_challenge(challenge, %{status: "complete"}) do\
        {:ok, _updated_challenge} ->\
          Phoenix.PubSub.broadcast(RepRivals.PubSub, "challenges", {:challenge_completed, challenge_id})\
          socket\
        {:error, _changeset} ->\
          socket\
      end\
    else\
      socket\
    end\
  end\

  defp format_date(date) do
    Calendar.strftime(date, "%B %d, %Y at %I:%M %p")
  end
end
