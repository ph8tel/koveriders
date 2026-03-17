defmodule KoveRidersWeb.UserLive.Registration do
  use KoveRidersWeb, :live_view

  alias KoveRiders.Accounts

  def mount(_params, _session, socket) do
    changeset = Accounts.change_user_email(%Accounts.User{})

    {:ok,
     socket
     |> assign(:page_title, "Create account")
     |> assign(:form, to_form(changeset, as: :user))}
  end

  def handle_event("save", %{"user" => %{"email" => email}}, socket) do
    case Accounts.register_user(%{"email" => email}) do
      {:ok, user} ->
        {:ok, _} =
          Accounts.deliver_login_instructions(user, fn token ->
            url(~p"/users/log-in/#{token}")
          end)

        {:noreply,
         socket
         |> put_flash(:info, "Account created! Check your email for a sign-in link.")
         |> push_navigate(to: ~p"/users/log-in")}

      {:error, changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset, as: :user))}
    end
  end

  def handle_event("validate", %{"user" => params}, socket) do
    changeset =
      %Accounts.User{}
      |> Accounts.change_user_email(params, validate_unique: false)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form, to_form(changeset, as: :user))}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="max-w-md mx-auto py-12 space-y-6">
        <div class="text-center space-y-2">
          <h1 class="text-3xl font-bold">Create your rider page</h1>
          <p class="text-base-content/60">We'll send you a magic link to get started.</p>
        </div>

        <div class="card bg-base-200 shadow-sm">
          <div class="card-body space-y-4">
            <.form for={@form} id="registration-form" phx-change="validate" phx-submit="save">
              <.input field={@form[:email]} type="email" label="Email address" required />
              <.button
                type="submit"
                class="btn btn-primary w-full mt-4"
                phx-disable-with="Sending link…"
              >
                Create account
              </.button>
            </.form>
          </div>
        </div>

        <p class="text-center text-sm text-base-content/60">
          Already have an account?
          <.link navigate={~p"/users/log-in"} class="link link-primary">Sign in</.link>
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
