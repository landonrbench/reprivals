defmodule RepRivalsWeb.ChallengesLive do
  use RepRivalsWeb, :live_view

  alias RepRivals.Library
  alias RepRivals.Accounts
  alias RepRivals.Library.Challenge
  alias RepRivals.Library.ChallengeParticipant

  @impl true
  def mount(_params, _session, socket) do
    current_user = socket.assigns.current_scope.user

    # Subscribe to challenges and participants updates
    Phoenix.PubSub.subscribe(RepRivals.PubSub, "challenges")

    challenges = Library.list_challenges_for_user(current_user.id)
    invites = Library.list_challenge_invites_for_user(current_user.id)
    workouts = Library.list_workouts_for_user(current_user.id)
    users = Accounts.list_users()

    {:ok,
     socket
     |> assign(:page_title, "Challenges")
     |> assign(:current_tab, "challenges")
     |> assign(:challenges, challenges)
     |> assign(:invites, invites)
     |> assign(:workouts, workouts)
     |> assign(:users, users)
     |> assign(:show_create_modal, false)
     |> assign(:show_complete_modal, false)
     |> assign(:create_form, to_form(Library.change_challenge(%Challenge{})))
     |> assign(
       :complete_form,
       to_form(Library.change_challenge_participant(%ChallengeParticipant{}))
     )
     |> assign(:challenge_participants, [])
     |> assign(:selected_participant_ids, [])
     |> assign(:completing_participant, nil)}
  end

  @impl true
  def handle_event("switch_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, :current_tab, tab)}
  end

  @impl true
  def handle_event("show_create_modal", _params, socket) do
    {:noreply,
     socket
     |> assign(:show_create_modal, true)
     |> assign(:create_form, to_form(Library.change_challenge(%Challenge{})))
     |> assign(:selected_participant_ids, [])}
  end

  @impl true
  def handle_event("hide_create_modal", _params, socket) do
    {:noreply, assign(socket, :show_create_modal, false)}
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
  def handle_event("validate_challenge", %{"challenge" => challenge_params}, socket) do
    changeset =
      %Challenge{}
      |> Library.change_challenge(challenge_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :create_form, to_form(changeset))}
  end

  @impl true
  def handle_event("create_challenge", %{"challenge" => challenge_params}, socket) do
    current_user = socket.assigns.current_scope.user

    # Add creator_id to challenge params
    challenge_attrs = Map.put(challenge_params, "creator_id", current_user.id)
    participant_ids = socket.assigns.selected_participant_ids

    # Always create group challenges where creator participates
    case Library.create_group_challenge(challenge_attrs, participant_ids) do
      {:ok, _challenge} ->
        current_user = socket.assigns.current_scope.user
        challenges = Library.list_challenges_for_user(current_user.id)

        {:noreply,
         socket
         |> assign(:challenges, challenges)
         |> assign(:show_create_modal, false)
         |> put_flash(:info, "Challenge created successfully!")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :create_form, to_form(changeset))}

      {:error, _reason} ->
        {:noreply, put_flash(socket, :error, "Failed to create challenge")}
    end
  end

  @impl true
  def handle_event("accept_challenge", %{"participant_id" => participant_id}, socket) do
    participant = Library.get_challenge_participant!(participant_id)

    case Library.update_challenge_participant(participant, %{status: "accepted"}) do
      {:ok, _updated_participant} ->
        current_user = socket.assigns.current_scope.user
        invites = Library.list_challenge_invites_for_user(current_user.id)

        {:noreply,
         socket
         |> assign(:invites, invites)
         |> put_flash(:info, "Challenge accepted!")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to accept challenge")}
    end
  end

  @impl true
  def handle_event("decline_challenge", %{"participant_id" => participant_id}, socket) do
    participant = Library.get_challenge_participant!(participant_id)

    case Library.update_challenge_participant(participant, %{status: "declined"}) do
      {:ok, _updated_participant} ->
        current_user = socket.assigns.current_scope.user
        invites = Library.list_challenge_invites_for_user(current_user.id)

        {:noreply,
         socket
         |> assign(:invites, invites)
         |> put_flash(:info, "Challenge declined")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to decline challenge")}
    end
  end

  @impl true
  def handle_event("complete_challenge", %{"participant_id" => participant_id}, socket) do
    participant = Library.get_challenge_participant!(participant_id)

    {:noreply,
     socket
     |> assign(:show_complete_modal, true)
     |> assign(:completing_participant, participant)
     |> assign(:complete_form, to_form(Library.change_challenge_participant(participant)))}
  end

  @impl true
  def handle_event("hide_complete_modal", _params, socket) do
    {:noreply,
     socket
     |> assign(:show_complete_modal, false)
     |> assign(:completing_participant, nil)}
  end

  @impl true
  def handle_event("validate_completion", %{"challenge_participant" => params}, socket) do
    participant = socket.assigns.completing_participant

    changeset =
      participant
      |> Library.change_challenge_participant(params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :complete_form, to_form(changeset))}
  end

  @impl true
  def handle_event("submit_completion", %{"challenge_participant" => params}, socket) do
    participant = socket.assigns.completing_participant

    completion_params =
      params
      |> Map.put("status", "completed")
      |> Map.put("completed_at", NaiveDateTime.utc_now())

    case Library.update_challenge_participant(participant, completion_params) do
      {:ok, _updated_participant} ->
        current_user = socket.assigns.current_scope.user
        invites = Library.list_challenge_invites_for_user(current_user.id)

        {:noreply,
         socket
         |> assign(:invites, invites)
         |> assign(:show_complete_modal, false)
         |> assign(:completing_participant, nil)
         |> put_flash(:info, "Challenge completed!")}

      {:error, changeset} ->
        {:noreply, assign(socket, :complete_form, to_form(changeset))}
    end
  end

  # PubSub event handlers
  @impl true
  def handle_info({:challenge_created, _challenge}, socket) do
    current_user = socket.assigns.current_scope.user
    challenges = Library.list_challenges_for_user(current_user.id)
    invites = Library.list_challenge_invites_for_user(current_user.id)

    {:noreply,
     socket
     |> assign(:challenges, challenges)
     |> assign(:invites, invites)}
  end

  @impl true
  def handle_info({:participants_invited, _participants}, socket) do
    current_user = socket.assigns.current_scope.user
    invites = Library.list_challenge_invites_for_user(current_user.id)

    {:noreply, assign(socket, :invites, invites)}
  end

  @impl true
  def handle_info({:participant_updated, _participant}, socket) do
    current_user = socket.assigns.current_scope.user
    invites = Library.list_challenge_invites_for_user(current_user.id)

    {:noreply, assign(socket, :invites, invites)}
  end

  @impl true
  def handle_info(_, socket), do: {:noreply, socket}

  # Helper functions
  defp format_date(date) when is_nil(date), do: "Not set"

  defp format_date(date) do
    Calendar.strftime(date, "%b %d, %Y")
  end

  defp participant_status_display("invited"), do: "⏳ Invited"
  defp participant_status_display("accepted"), do: "✅ Accepted"
  defp participant_status_display("completed"), do: "🏁 Complete"
  defp participant_status_display("declined"), do: "❌ Declined"
  defp participant_status_display(_), do: "❓ Unknown"

  defp challenge_status_display("active"), do: "🟢 Active"
  defp challenge_status_display("completed"), do: "🏁 Completed"
  defp challenge_status_display("expired"), do: "⏰ Expired"
  defp challenge_status_display(_), do: "❓ Unknown"

  defp format_result_with_unit(result_value, result_unit) when is_nil(result_value) do
    "No result yet"
  end

  defp format_result_with_unit(result_value, result_unit) do
    formatted_value =
      case result_value do
        %Decimal{} ->
          result_value
          |> Decimal.to_string()
          |> String.replace(~r/\.?0+$/, "")

        _ ->
          to_string(result_value)
      end

    case result_unit do
      nil -> formatted_value
      "" -> formatted_value
      unit -> "#{formatted_value} #{unit}"
    end
  end

  defp user_is_selected?(user_id, selected_ids) do
    user_id in selected_ids
  end
end
