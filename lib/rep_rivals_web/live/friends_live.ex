defmodule RepRivalsWeb.FriendsLive do
  use RepRivalsWeb, :live_view

  alias RepRivals.Accounts

  @impl true
  def mount(_params, _session, socket) do
    user_id = socket.assigns.current_scope.user.id

    # Get all friend-related data
    friends = Accounts.list_friends(user_id)
    pending_requests = Accounts.list_pending_friend_requests(user_id)
    sent_requests = Accounts.list_sent_friend_requests(user_id)

    {:ok,
     socket
     |> assign(:page_title, "Friends")
     |> assign(:friends, friends)
     |> assign(:pending_requests, pending_requests)
     |> assign(:sent_requests, sent_requests)
     |> assign(:show_add_friend_modal, false)
     |> assign(:friend_email, "")
     |> assign(:add_friend_error, nil)}
  end

  @impl true
  def handle_event("show_add_friend_modal", _params, socket) do
    {:noreply,
     assign(socket, show_add_friend_modal: true, friend_email: "", add_friend_error: nil)}
  end

  @impl true
  def handle_event("hide_add_friend_modal", _params, socket) do
    {:noreply,
     assign(socket, show_add_friend_modal: false, friend_email: "", add_friend_error: nil)}
  end

  @impl true
  def handle_event("add_friend", %{"email" => email}, socket) do
    current_user_id = socket.assigns.current_scope.user.id

    case Accounts.find_user_by_email(email) do
      nil ->
        {:noreply, assign(socket, add_friend_error: "User not found with that email")}

      user when user.id == current_user_id ->
        {:noreply, assign(socket, add_friend_error: "You cannot add yourself as a friend")}

      user ->
        if Accounts.friendship_exists?(current_user_id, user.id) do
          {:noreply, assign(socket, add_friend_error: "Friend request already exists")}
        else
          case Accounts.send_friend_request(current_user_id, user.id) do
            {:ok, _friendship} ->
              # Refresh sent requests
              sent_requests = Accounts.list_sent_friend_requests(current_user_id)

              {:noreply,
               socket
               |> assign(:sent_requests, sent_requests)
               |> assign(:show_add_friend_modal, false)
               |> assign(:friend_email, "")
               |> assign(:add_friend_error, nil)
               |> put_flash(:info, "Friend request sent successfully!")}

            {:error, _changeset} ->
              {:noreply, assign(socket, add_friend_error: "Failed to send friend request")}
          end
        end
    end
  end

  @impl true
  def handle_event("accept_request", %{"id" => friendship_id}, socket) do
    friendship = Accounts.get_friendship!(friendship_id)
    user_id = socket.assigns.current_scope.user.id

    case Accounts.accept_friend_request(friendship) do
      {:ok, _friendship} ->
        # Refresh all friend data
        friends = Accounts.list_friends(user_id)
        pending_requests = Accounts.list_pending_friend_requests(user_id)

        {:noreply,
         socket
         |> assign(:friends, friends)
         |> assign(:pending_requests, pending_requests)
         |> put_flash(:info, "Friend request accepted!")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to accept friend request")}
    end
  end

  @impl true
  def handle_event("decline_request", %{"id" => friendship_id}, socket) do
    friendship = Accounts.get_friendship!(friendship_id)
    user_id = socket.assigns.current_scope.user.id

    case Accounts.decline_friend_request(friendship) do
      {:ok, _friendship} ->
        # Refresh pending requests
        pending_requests = Accounts.list_pending_friend_requests(user_id)

        {:noreply,
         socket
         |> assign(:pending_requests, pending_requests)
         |> put_flash(:info, "Friend request declined")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to decline friend request")}
    end
  end

  @impl true
  def handle_event("back_to_home", _params, socket) do
    {:noreply, push_navigate(socket, to: ~p"/")}
  end

  defp get_friend_email_initials(email) do
    email
    |> String.split("@")
    |> hd()
    |> String.upcase()
    |> String.slice(0, 2)
  end
end
