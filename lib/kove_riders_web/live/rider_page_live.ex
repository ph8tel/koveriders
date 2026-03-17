defmodule KoveRidersWeb.RiderPageLive do
  use KoveRidersWeb, :live_view

  alias KoveRiders.Accounts
  alias KoveRiders.UserBikes
  alias KoveRiders.UserBikes.UserBike
  alias KoveRiders.Currency

  def mount(%{"handle" => handle}, _session, socket) do
    case Accounts.get_user_by_handle(handle) do
      nil ->
        {:ok,
         socket
         |> put_flash(:error, "Rider not found.")
         |> push_navigate(to: ~p"/")}

      rider ->
        bikes = UserBikes.list_public_user_bikes(rider)

        og_image =
          case bikes do
            [%{images: [img | _]} | _] -> img.url
            _ -> nil
          end

        bike_names =
          bikes
          |> Enum.map(fn ub -> "#{ub.year} #{UserBike.model_label(ub.model)}" end)
          |> Enum.join(", ")

        og_description =
          cond do
            bikes == [] -> "#{rider.handle}'s rider page on KoveRiders."
            true -> "#{rider.handle} rides: #{bike_names}"
          end

        {:ok,
         socket
         |> assign(:page_title, "@#{rider.handle} — KoveRiders")
         |> assign(:og_title, "@#{rider.handle} — KoveRiders")
         |> assign(:og_description, og_description)
         |> assign(:og_image, og_image)
         |> assign(:og_url, url(~p"/@#{handle}"))
         |> assign(:og_type, "profile")
         |> assign(:rider, rider)
         |> assign(:bikes, bikes)}
    end
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="max-w-4xl mx-auto space-y-8">
        <%!-- Rider header --%>
        <div class="flex items-center gap-4">
          <div class="avatar placeholder">
            <div class="bg-primary text-primary-content rounded-full w-16">
              <span class="text-2xl font-bold">{String.first(@rider.handle) |> String.upcase()}</span>
            </div>
          </div>
          <div>
            <h1 class="text-3xl font-bold">@{@rider.handle}</h1>
            <p class="text-base-content/50 text-sm">KoveRiders member</p>
          </div>

          <div class="ml-auto">
            <button
              onclick="navigator.clipboard.writeText(window.location.href); this.textContent='Copied!'; setTimeout(() => this.textContent='Share', 1500)"
              class="btn btn-outline btn-sm gap-2"
            >
              <.icon name="hero-share" class="size-4" /> Share
            </button>
          </div>
        </div>

        <%!-- Bikes --%>
        <%= if @bikes == [] do %>
          <div class="py-16 text-center text-base-content/40">
            <.icon name="hero-wrench-screwdriver" class="size-12 mx-auto mb-3 opacity-30" />
            <p>{@rider.handle} hasn't added any bikes yet.</p>
          </div>
        <% else %>
          <div class="space-y-8">
            <%= for ub <- @bikes do %>
              <div id={"ub-#{ub.id}"} class="card bg-base-200 shadow-md">
                <%!-- Bike photo carousel --%>
                <%= if ub.images != [] do %>
                  <figure class="aspect-video rounded-t-2xl overflow-hidden bg-base-300">
                    <img
                      src={List.first(ub.images).url}
                      alt={List.first(ub.images).caption || "Bike photo"}
                      class="w-full h-full object-cover"
                    />
                  </figure>
                <% end %>

                <div class="card-body">
                  <div class="flex items-start justify-between gap-4">
                    <div>
                      <h2 class="card-title text-xl">
                        {if ub.nickname && ub.nickname != "",
                          do: ub.nickname,
                          else: "#{ub.year} #{UserBike.model_label(ub.model)}"}
                      </h2>
                      <p class="text-base-content/50 text-sm">
                        {ub.year} {UserBike.model_label(ub.model)} · {ub.mileage} miles
                      </p>
                    </div>
                  </div>

                  <%!-- Mods --%>
                  <%= if ub.mods != [] do %>
                    <div class="mt-4">
                      <h3 class="text-sm font-semibold uppercase tracking-wider text-base-content/50 mb-3">
                        Modifications ({length(ub.mods)})
                      </h3>
                      <div class="grid gap-2">
                        <%= for mod <- ub.mods do %>
                          <div class="flex items-start gap-3 p-3 bg-base-300 rounded-lg">
                            <span class="badge badge-outline badge-sm mt-0.5 shrink-0">
                              {mod.category}
                            </span>
                            <div class="flex-1 min-w-0">
                              <div class="flex items-center gap-2 flex-wrap">
                                <span class="font-medium text-sm">{mod.title}</span>
                                <%= if mod.brand do %>
                                  <span class="text-xs text-base-content/40">by {mod.brand}</span>
                                <% end %>
                                <%= if mod.rating do %>
                                  <span class="text-xs text-warning">
                                    {"★" |> String.duplicate(mod.rating)}
                                  </span>
                                <% end %>
                              </div>
                              <%= if mod.description do %>
                                <p class="text-xs text-base-content/50 mt-0.5">{mod.description}</p>
                              <% end %>
                            </div>
                            <%= if mod.cost_cents do %>
                              <span class="text-xs font-medium text-base-content/60 shrink-0">
                                {Currency.format(mod.cost_cents)}
                              </span>
                            <% end %>
                          </div>
                        <% end %>
                      </div>
                    </div>
                  <% end %>

                  <%!-- Extra photos --%>
                  <%= if length(ub.images) > 1 do %>
                    <div class="mt-4">
                      <h3 class="text-sm font-semibold uppercase tracking-wider text-base-content/50 mb-3">
                        More Photos
                      </h3>
                      <div class="grid grid-cols-3 gap-2">
                        <%= for img <- Enum.drop(ub.images, 1) do %>
                          <div class="aspect-square rounded-lg overflow-hidden bg-base-300">
                            <img
                              src={img.url}
                              alt={img.caption || ""}
                              class="w-full h-full object-cover"
                            />
                          </div>
                        <% end %>
                      </div>
                    </div>
                  <% end %>
                </div>
              </div>
            <% end %>
          </div>
        <% end %>
      </div>
    </Layouts.app>
    """
  end
end
