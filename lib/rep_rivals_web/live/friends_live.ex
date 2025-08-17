defmodule RepRivalsWeb.FriendsLive do
  use RepRivalsWeb, :live_view

  alias RepRivals.Accounts

  @impl true
  def mount(_params, _session, socket) do
    scope = socket.assigns.current_scope
    friends = Accounts.list_friends(scope)
    pending_requests = Accounts.list_pending_friend_requests(scope)
    sent_requests = Accounts.list_sent_friend_requests(scope)

    {:ok,
     socket
     |> assign(:friends, friends)
     |> assign(:pending_requests, pending_requests)
     |> assign(:sent_requests, sent_requests)
     |> assign(:friends_empty?, friends == [])
     |> assign(:show_add_form?, false)
     |> assign(:friend_email, "")}
  end

  @impl true
  def handle_event("add_friend", _params, socket) do
    {:noreply, assign(socket, :show_add_form?, true)}
  end

  @impl true
  def handle_event("cancel_add", _params, socket) do
    {:noreply,
     socket
     |> assign(:show_add_form?, false)
     |> assign(:friend_email, "")}
  end

  @impl true
  def handle_event("update_email", %{"email" => email}, socket) do
    {:noreply, assign(socket, :friend_email, email)}
  end

  @impl true
  def handle_event("send_request", %{"email" => email}, socket) do
    scope = socket.assigns.current_scope
    current_user_email = scope.user.email

    case String.trim(email) do
      "" ->
        {:noreply, put_flash(socket, :error, "Please enter an email address")}

      ^current_user_email ->
        {:noreply, put_flash(socket, :error, "You can't add yourself as a friend!")}

      email ->
        case Accounts.get_user_by_email(email) do
          nil ->
            {:noreply, put_flash(socket, :error, "User not found with email: #{email}")}

          friend ->
            if Accounts.friendship_exists?(scope.user.id, friend.id) do
              {:noreply,
               put_flash(
                 socket,
                 :error,
                 "Friend request already exists or you're already friends with "
               )}
            else
              case Accounts.send_friend_request(scope, friend.id) do
                {:ok, _friendship} ->
                  # Refresh sent requests
                  sent_requests = Accounts.list_sent_friend_requests(scope)

                  {:noreply,
                   socket
                   |> assign(:sent_requests, sent_requests)
                   |> assign(:show_add_form?, false)
                   |> assign(:friend_email, "")
                   |> put_flash(:info, "Friend request sent to #{email}!")}

                {:error, _changeset} ->
                  {:noreply, put_flash(socket, :error, "Failed to send friend request")}
              end
            end
        end
    end
  end

  @impl true
  def handle_event("accept_request", %{"id" => id}, socket) do
    scope = socket.assigns.current_scope
    friendship = Accounts.get_friendship!(id)

    case Accounts.accept_friend_request(scope, friendship) do
      {:ok, _friendship} ->
        # Refresh all friend data
        friends = Accounts.list_friends(scope)
        pending_requests = Accounts.list_pending_friend_requests(scope)

        {:noreply,
         socket
         |> assign(:friends, friends)
         |> assign(:pending_requests, pending_requests)
         |> assign(:friends_empty?, friends == [])
         |> put_flash(:info, "Friend request accepted!")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to accept friend request")}
    end
  end

  @impl true
  def handle_event("decline_request", %{"id" => id}, socket) do
    scope = socket.assigns.current_scope
    friendship = Accounts.get_friendship!(id)

    case Accounts.decline_friend_request(scope, friendship) do
      {:ok, _friendship} ->
        pending_requests = Accounts.list_pending_friend_requests(scope)

        {:noreply,
         socket
         |> assign(:pending_requests, pending_requests)
         |> put_flash(:info, "Friend request declined")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to decline friend request")}
    end
  end

  defp format_date(datetime) do
    datetime
    |> DateTime.to_date()
    |> Date.to_string()
    |> String.replace("-", "/")
  end
end
