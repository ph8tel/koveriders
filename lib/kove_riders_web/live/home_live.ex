defmodule KoveRidersWeb.HomeLive do
  use KoveRidersWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "KoveRiders — Share Your Ride")}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="max-w-3xl mx-auto text-center py-20 space-y-6">
        <h1 class="text-5xl font-bold tracking-tight text-primary">KoveRiders</h1>
        <p class="text-xl text-base-content/70">
          Show the world your Kove. Share your bike, your mods, your miles.
        </p>
        <div class="flex justify-center gap-4 pt-4">
          <%= if @current_scope && @current_scope.user do %>
            <.link navigate={~p"/garage"} class="btn btn-primary btn-lg">
              <.icon name="hero-wrench-screwdriver" class="size-5" /> My Garage
            </.link>
            <.link navigate={~p"/@#{@current_scope.user.handle}"} class="btn btn-ghost btn-lg">
              My Rider Page
            </.link>
          <% else %>
            <.link navigate={~p"/users/register"} class="btn btn-primary btn-lg">
              Create Your Rider Page
            </.link>
            <.link navigate={~p"/users/log-in"} class="btn btn-ghost btn-lg">
              Sign in
            </.link>
          <% end %>
        </div>
      </div>
    </Layouts.app>
    """
  end
end
