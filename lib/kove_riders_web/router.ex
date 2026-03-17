defmodule KoveRidersWeb.Router do
  use KoveRidersWeb, :router

  import KoveRidersWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {KoveRidersWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_scope_for_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", KoveRidersWeb do
    pipe_through :browser

    live_session :current_user,
      on_mount: [{KoveRidersWeb.UserAuth, :mount_current_scope}] do
      live "/", HomeLive, :index
      live "/@:handle", RiderPageLive, :index
    end
  end

  scope "/auth", KoveRidersWeb do
    pipe_through :browser

    get "/google", GoogleAuthController, :request
    get "/google/callback", GoogleAuthController, :callback
  end

  scope "/", KoveRidersWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    live_session :redirect_if_user_is_authenticated,
      on_mount: [{KoveRidersWeb.UserAuth, :mount_current_scope}] do
      live "/users/register", UserLive.Registration, :new
      live "/users/log-in", UserLive.Login, :new
      live "/users/log-in/:token", UserLive.Confirmation, :new
    end

    post "/users/log-in", UserSessionController, :create
  end

  scope "/", KoveRidersWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_authenticated_user,
      on_mount: [{KoveRidersWeb.UserAuth, :require_authenticated}] do
      live "/garage", GarageLive, :index
      live "/garage/:id", GarageLive, :show
      live "/users/settings", UserLive.Settings, :edit
      live "/users/settings/confirm-email/:token", UserLive.Settings, :confirm_email
    end

    delete "/users/log-out", UserSessionController, :delete
  end

  if Application.compile_env(:kove_riders, :dev_routes) do
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: KoveRidersWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
