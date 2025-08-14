defmodule RepRivalsWeb.UserLive.Confirmation do
  use RepRivalsWeb, :live_view

  alias RepRivals.Accounts

  def render(%{live_action: :new} = assigns) do
    ~H"""
    <RepRivalsWeb.Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="mx-auto max-w-sm space-y-4">
        <.header class="text-center">
          Confirm account
          <:subtitle>We'll send a confirmation link to your inbox</:subtitle>
        </.header>

        <.simple_form for={@form} id="confirmation_form" phx-submit="send_instructions">
          <.input field={@form[:email]} type="email" placeholder="Email" required />
          <:actions>
            <.button phx-disable-with="Sending..." class="w-full">
              Send confirmation instructions
            </.button>
          </:actions>
        </.simple_form>

        <p class="text-center">
          <.link navigate={~p"/users/register"}>Register</.link>
          | <.link navigate={~p"/users/log-in"}>Log in</.link>
        </p>
      </div>
    </RepRivalsWeb.Layouts.app>
    """
  end

  def render(%{live_action: :edit} = assigns) do
    ~H"""
    <RepRivalsWeb.Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="mx-auto max-w-sm space-y-4">
        <.header class="text-center">Confirm account</.header>

        <.simple_form for={@form} id="confirmation_form" phx-submit="confirm_account">
          <input type="hidden" name="token" value={@token} />
          <:actions>
            <.button phx-disable-with="Confirming..." class="w-full">
              Confirm my account
            </.button>
          </:actions>
        </.simple_form>

        <p class="text-center">
          <.link navigate={~p"/users/register"}>Register</.link>
          | <.link navigate={~p"/users/log-in"}>Log in</.link>
        </p>
      </div>
    </RepRivalsWeb.Layouts.app>
    """
  end

  def mount(params, _session, socket) do
    form = to_form(%{}, as: "user")
    socket = assign(socket, form: form, token: params["token"])
    {:ok, socket, temporary_assigns: [form: form]}
  end

  def handle_event("send_instructions", %{"user" => user_params}, socket) do
    %{"email" => email} = user_params

    if user = Accounts.get_user_by_email(email) do
      Accounts.deliver_user_confirmation_instructions(
        user,
        &url(~p"/users/confirm/#{&1}")
      )
    end

    info =
      "If your email is in our system and it has not been confirmed yet, you will receive an email with instructions shortly."

    {:noreply,
     socket
     |> put_flash(:info, info)
     |> redirect(to: ~p"/")}
  end

  def handle_event("confirm_account", %{"token" => token}, socket) do
    case Accounts.confirm_user(token) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "User confirmed successfully.")
         |> redirect(to: ~p"/")}

      :error ->
        # If there is a current user and the account was already confirmed,
        # then odds are that the confirmation link was already visited, either
        # by some automation or by the user themselves, so we redirect without
        # a warning message.
        case socket.assigns do
          %{current_scope: %{user: %{confirmed_at: %DateTime{}}}} ->
            {:noreply, redirect(socket, to: ~p"/")}

          %{} ->
            {:noreply,
             socket
             |> put_flash(:error, "User confirmation link is invalid or it has expired.")
             |> redirect(to: ~p"/")}
        end
    end
  end
end
