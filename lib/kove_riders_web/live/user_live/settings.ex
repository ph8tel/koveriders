defmodule KoveRidersWeb.UserLive.Settings do
  use KoveRidersWeb, :live_view

  alias KoveRiders.Accounts
  alias KoveRiders.Accounts.User

  def mount(_params, _session, socket) do
    user = socket.assigns.current_scope.user

    {:ok,
     socket
     |> assign(:page_title, "Account Settings")
     |> assign(:user, user)
     |> assign(
       :email_form,
       to_form(Accounts.change_user_email(user, %{}, validate_unique: false), as: :user)
     )
     |> assign(:password_form, to_form(Accounts.change_user_password(user), as: :user))
     |> assign(
       :handle_form,
       to_form(Accounts.change_user_handle(user, %{}, validate_unique: false), as: :user)
     )
     |> assign(:email_updated, false)}
  end

  def handle_params(%{"token" => token}, _uri, socket) do
    case Accounts.update_user_email(socket.assigns.user, token) do
      {:ok, user} ->
        {:noreply,
         socket
         |> put_flash(:info, "Email updated successfully.")
         |> assign(:user, user)
         |> push_patch(to: ~p"/users/settings")}

      {:error, _} ->
        {:noreply,
         socket
         |> put_flash(:error, "Email change link is invalid or has expired.")
         |> push_patch(to: ~p"/users/settings")}
    end
  end

  def handle_params(_params, _uri, socket), do: {:noreply, socket}

  def handle_event("update_email", %{"user" => params}, socket) do
    user = socket.assigns.user

    case Accounts.deliver_user_update_email_instructions(
           user,
           user.email,
           fn token -> url(~p"/users/settings/confirm-email/#{token}") end
         ) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "A link to confirm your email change has been sent.")
         |> assign(
           :email_form,
           to_form(Accounts.change_user_email(user, params, validate_unique: false), as: :user)
         )}

      {:error, changeset} ->
        {:noreply, assign(socket, :email_form, to_form(changeset, as: :user))}
    end
  end

  def handle_event("validate_email", %{"user" => params}, socket) do
    changeset =
      socket.assigns.user
      |> Accounts.change_user_email(params, validate_unique: false)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :email_form, to_form(changeset, as: :user))}
  end

  def handle_event("update_password", %{"user" => params}, socket) do
    user = socket.assigns.user

    case Accounts.update_user_password(user, params) do
      {:ok, {_user, _tokens}} ->
        {:noreply,
         socket
         |> put_flash(:info, "Password updated. Please log in again.")
         |> push_navigate(to: ~p"/users/log-in")}

      {:error, changeset} ->
        {:noreply, assign(socket, :password_form, to_form(changeset, as: :user))}
    end
  end

  def handle_event("validate_password", %{"user" => params}, socket) do
    changeset =
      socket.assigns.user
      |> Accounts.change_user_password(params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :password_form, to_form(changeset, as: :user))}
  end

  def handle_event("update_handle", %{"user" => %{"handle" => handle}}, socket) do
    user = socket.assigns.user

    case Accounts.update_user_handle(user, %{handle: handle}) do
      {:ok, updated_user} ->
        {:noreply,
         socket
         |> put_flash(:info, "Handle updated to @#{updated_user.handle}.")
         |> assign(:user, updated_user)
         |> assign(
           :handle_form,
           to_form(Accounts.change_user_handle(updated_user, %{}, validate_unique: false),
             as: :user
           )
         )}

      {:error, :locked} ->
        {:noreply, put_flash(socket, :error, "You have used all your handle changes.")}

      {:error, changeset} ->
        {:noreply, assign(socket, :handle_form, to_form(changeset, as: :user))}
    end
  end

  def handle_event("validate_handle", %{"user" => params}, socket) do
    changeset =
      socket.assigns.user
      |> Accounts.change_user_handle(params, validate_unique: false)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :handle_form, to_form(changeset, as: :user))}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="max-w-2xl mx-auto space-y-8">
        <h1 class="text-3xl font-bold">Account Settings</h1>

        <%!-- Handle section --%>
        <div class="card bg-base-200 shadow-sm">
          <div class="card-body space-y-4">
            <h2 class="card-title">Your Rider Handle</h2>
            <p class="text-sm text-base-content/60">
              Your handle is your public URL: <strong>koveriders.com/@{@user.handle}</strong>
            </p>

            <%= cond do %>
              <% User.handle_locked?(@user) -> %>
                <div class="alert alert-warning">
                  <.icon name="hero-lock-closed" class="size-4" />
                  <span>
                    You have used all your handle changes. Your handle is permanently <strong>@{@user.handle}</strong>.
                  </span>
                </div>
              <% User.handle_changes_remaining(@user) == 1 -> %>
                <div class="alert alert-warning">
                  <.icon name="hero-exclamation-triangle" class="size-4" />
                  <span>
                    <strong>Last change available.</strong>
                    Changing your handle will break existing shared links.
                  </span>
                </div>
                <.form
                  for={@handle_form}
                  id="handle-form"
                  phx-change="validate_handle"
                  phx-submit="update_handle"
                >
                  <.input field={@handle_form[:handle]} type="text" label="Handle" />
                  <.button type="submit" class="btn btn-warning mt-3">
                    Change handle (final time)
                  </.button>
                </.form>
              <% true -> %>
                <p class="text-xs text-base-content/50">
                  {User.handle_changes_remaining(@user)} change(s) remaining. Changing your handle will break existing shared links.
                </p>
                <.form
                  for={@handle_form}
                  id="handle-form"
                  phx-change="validate_handle"
                  phx-submit="update_handle"
                >
                  <.input field={@handle_form[:handle]} type="text" label="Handle" />
                  <.button type="submit" class="btn btn-primary mt-3">Update handle</.button>
                </.form>
            <% end %>
          </div>
        </div>

        <%!-- Email section --%>
        <div class="card bg-base-200 shadow-sm">
          <div class="card-body space-y-4">
            <h2 class="card-title">Email Address</h2>
            <.form
              for={@email_form}
              id="email-form"
              phx-change="validate_email"
              phx-submit="update_email"
            >
              <.input field={@email_form[:email]} type="email" label="Email" />
              <.button type="submit" class="btn btn-primary mt-3">Update email</.button>
            </.form>
          </div>
        </div>

        <%!-- Password section --%>
        <div class="card bg-base-200 shadow-sm">
          <div class="card-body space-y-4">
            <h2 class="card-title">Change Password</h2>
            <.form
              for={@password_form}
              id="password-form"
              phx-change="validate_password"
              phx-submit="update_password"
            >
              <.input field={@password_form[:password]} type="password" label="New password" />
              <.input
                field={@password_form[:password_confirmation]}
                type="password"
                label="Confirm new password"
              />
              <.button type="submit" class="btn btn-primary mt-3">Update password</.button>
            </.form>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end
end
