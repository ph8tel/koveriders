defmodule KoveRidersWeb.UserLive.Confirmation do
  use KoveRidersWeb, :live_view

  alias KoveRiders.Accounts
  alias KoveRidersWeb.UserAuth

  def mount(%{"token" => token}, _session, socket) do
    {:ok, assign(socket, :token, token)}
  end

  def handle_params(_params, _uri, socket) do
    case Accounts.login_user_by_magic_link(socket.assigns.token) do
      {:ok, {user, _expired_tokens}} ->
        {:noreply,
         socket
         |> put_flash(:info, "Welcome back!")
         |> UserAuth.log_in_user(user)}

      {:error, _} ->
        {:noreply,
         socket
         |> put_flash(:error, "This sign-in link is invalid or has expired.")
         |> push_navigate(to: ~p"/users/log-in")}
    end
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="max-w-md mx-auto py-20 text-center">
        <span class="loading loading-spinner loading-lg text-primary"></span>
        <p class="mt-4 text-base-content/60">Signing you in…</p>
      </div>
    </Layouts.app>
    """
  end
end
