defmodule KoveRidersWeb.UserLive.Login do
  use KoveRidersWeb, :live_view

  alias KoveRiders.Accounts

  def mount(_params, _session, socket) do
    email = Phoenix.Flash.get(socket.assigns.flash, :email)
    form = to_form(%{"email" => email}, as: :user)

    {:ok,
     socket
     |> assign(:page_title, "Sign in")
     |> assign(:form, form)}
  end

  def handle_event("send_magic_link", %{"user" => %{"email" => email}}, socket) do
    if user = Accounts.get_user_by_email(email) do
      Accounts.deliver_login_instructions(user, fn token ->
        url(~p"/users/log-in/#{token}")
      end)
    end

    # Always show success to prevent email enumeration
    {:noreply,
     socket
     |> put_flash(:info, "If that email is registered, you'll receive a sign-in link shortly.")
     |> push_navigate(to: ~p"/users/log-in")}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="max-w-md mx-auto py-12 space-y-6">
        <div class="text-center space-y-2">
          <h1 class="text-3xl font-bold">Sign in</h1>
          <p class="text-base-content/60">Enter your email to receive a magic sign-in link.</p>
        </div>

        <div class="card bg-base-200 shadow-sm">
          <div class="card-body space-y-4">
            <.form for={@form} id="login-form" phx-submit="send_magic_link">
              <.input field={@form[:email]} type="email" label="Email address" required />
              <.button type="submit" class="btn btn-primary w-full mt-4" phx-disable-with="Sending…">
                Send sign-in link
              </.button>
            </.form>
          </div>
        </div>

        <p class="text-center text-sm text-base-content/60">
          New here?
          <.link navigate={~p"/users/register"} class="link link-primary">Create an account</.link>
        </p>

        <div class="divider text-xs">or sign in with</div>

        <a href={~p"/auth/google"} class="btn btn-outline w-full gap-2">
          <svg class="size-5" viewBox="0 0 24 24" fill="currentColor">
            <path
              d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"
              fill="#4285F4"
            />
            <path
              d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"
              fill="#34A853"
            />
            <path
              d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l3.66-2.84z"
              fill="#FBBC05"
            />
            <path
              d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z"
              fill="#EA4335"
            />
          </svg>
          Continue with Google
        </a>
      </div>
    </Layouts.app>
    """
  end
end
