defmodule KoveRidersWeb.GarageLive do
  use KoveRidersWeb, :live_view

  alias KoveRiders.UserBikes
  alias KoveRiders.UserBikes.{UserBike, UserBikeMod}
  alias KoveRiders.Currency

  # ── Lifecycle ────────────────────────────────────────────────────────────────

  def mount(_params, _session, socket) do
    user_bikes = UserBikes.list_user_bikes(socket.assigns.current_scope)

    {:ok,
     socket
     |> assign(:page_title, "My Garage")
     |> assign(:user_bikes, user_bikes)
     |> assign(:active_tab, :mods)
     |> assign(:show_add_bike_modal, false)
     |> assign(:show_add_mod_modal, false)
     |> assign(:show_upload_modal, false)
     |> assign(:editing_mod, nil)
     |> assign(:add_bike_form, to_form(UserBike.changeset(%UserBike{}, %{})))
     |> assign(:mod_form, to_form(UserBikeMod.changeset(%UserBikeMod{}, %{})))
     |> allow_upload(:photo,
       accept: ~w(.jpg .jpeg .png .webp),
       max_entries: 10,
       max_file_size: 10_000_000
     )}
  end

  def handle_params(%{"id" => id}, _uri, socket) do
    bike = UserBikes.get_user_bike!(socket.assigns.current_scope, String.to_integer(id))
    {:noreply, assign(socket, :selected_bike, bike)}
  end

  def handle_params(_params, _uri, socket) do
    selected =
      case socket.assigns.user_bikes do
        [first | _] -> first
        [] -> nil
      end

    {:noreply, assign(socket, :selected_bike, selected)}
  end

  # ── Bike management ──────────────────────────────────────────────────────────

  def handle_event("show_add_bike", _, socket) do
    {:noreply,
     socket
     |> assign(:show_add_bike_modal, true)
     |> assign(:add_bike_form, to_form(UserBike.changeset(%UserBike{}, %{})))}
  end

  def handle_event("hide_add_bike", _, socket) do
    {:noreply, assign(socket, :show_add_bike_modal, false)}
  end

  def handle_event("add_bike", %{"user_bike" => params}, socket) do
    case UserBikes.create_user_bike(socket.assigns.current_scope, params) do
      {:ok, new_bike} ->
        new_bike = UserBikes.get_user_bike!(socket.assigns.current_scope, new_bike.id)
        user_bikes = UserBikes.list_user_bikes(socket.assigns.current_scope)

        {:noreply,
         socket
         |> assign(:user_bikes, user_bikes)
         |> assign(:selected_bike, new_bike)
         |> assign(:show_add_bike_modal, false)
         |> put_flash(:info, "Bike added to garage!")}

      {:error, changeset} ->
        {:noreply, assign(socket, :add_bike_form, to_form(changeset, as: :user_bike))}
    end
  end

  def handle_event("validate_add_bike", %{"user_bike" => params}, socket) do
    cs = UserBike.changeset(%UserBike{}, params) |> Map.put(:action, :validate)
    {:noreply, assign(socket, :add_bike_form, to_form(cs, as: :user_bike))}
  end

  def handle_event("select_bike", %{"id" => id}, socket) do
    {:noreply, push_patch(socket, to: ~p"/garage/#{id}")}
  end

  def handle_event("toggle_public", _, socket) do
    bike = socket.assigns.selected_bike
    scope = socket.assigns.current_scope

    {:ok, updated} = UserBikes.update_user_bike(scope, bike.id, %{is_public: !bike.is_public})
    updated = UserBikes.get_user_bike!(scope, updated.id)

    user_bikes =
      Enum.map(socket.assigns.user_bikes, fn b ->
        if b.id == updated.id, do: updated, else: b
      end)

    {:noreply,
     socket
     |> assign(:selected_bike, updated)
     |> assign(:user_bikes, user_bikes)}
  end

  def handle_event("set_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, :active_tab, String.to_existing_atom(tab))}
  end

  # ── Mods ────────────────────────────────────────────────────────────────────

  def handle_event("show_add_mod", _, socket) do
    {:noreply,
     socket
     |> assign(:show_add_mod_modal, true)
     |> assign(:editing_mod, nil)
     |> assign(:mod_form, to_form(UserBikeMod.changeset(%UserBikeMod{}, %{})))}
  end

  def handle_event("show_edit_mod", %{"id" => id}, socket) do
    mod =
      Enum.find(socket.assigns.selected_bike.mods, &(to_string(&1.id) == id))

    {:noreply,
     socket
     |> assign(:show_add_mod_modal, true)
     |> assign(:editing_mod, mod)
     |> assign(:mod_form, to_form(UserBikeMod.changeset(mod, %{})))}
  end

  def handle_event("hide_mod_modal", _, socket) do
    {:noreply,
     socket
     |> assign(:show_add_mod_modal, false)
     |> assign(:editing_mod, nil)}
  end

  def handle_event("save_mod", %{"user_bike_mod" => params}, socket) do
    scope = socket.assigns.current_scope
    bike = socket.assigns.selected_bike
    params = dollars_to_cents(params)

    result =
      case socket.assigns.editing_mod do
        nil -> UserBikes.add_mod(scope, bike.id, params)
        mod -> UserBikes.update_mod(scope, mod.id, params)
      end

    case result do
      {:ok, _} ->
        updated_bike = UserBikes.get_user_bike!(scope, bike.id)

        user_bikes =
          Enum.map(socket.assigns.user_bikes, fn b ->
            if b.id == updated_bike.id, do: updated_bike, else: b
          end)

        {:noreply,
         socket
         |> assign(:selected_bike, updated_bike)
         |> assign(:user_bikes, user_bikes)
         |> assign(:show_add_mod_modal, false)
         |> assign(:editing_mod, nil)
         |> put_flash(:info, "Mod saved!")}

      {:error, changeset} ->
        {:noreply, assign(socket, :mod_form, to_form(changeset, as: :user_bike_mod))}
    end
  end

  def handle_event("validate_mod", %{"user_bike_mod" => params}, socket) do
    base = socket.assigns.editing_mod || %UserBikeMod{}
    cs = UserBikeMod.changeset(base, dollars_to_cents(params)) |> Map.put(:action, :validate)
    {:noreply, assign(socket, :mod_form, to_form(cs, as: :user_bike_mod))}
  end

  def handle_event("delete_mod", %{"id" => id}, socket) do
    scope = socket.assigns.current_scope
    bike = socket.assigns.selected_bike
    UserBikes.delete_mod(scope, String.to_integer(id))

    updated_bike = UserBikes.get_user_bike!(scope, bike.id)

    user_bikes =
      Enum.map(socket.assigns.user_bikes, fn b ->
        if b.id == updated_bike.id, do: updated_bike, else: b
      end)

    {:noreply,
     socket
     |> assign(:selected_bike, updated_bike)
     |> assign(:user_bikes, user_bikes)
     |> put_flash(:info, "Mod removed.")}
  end

  # ── Photos ───────────────────────────────────────────────────────────────────

  def handle_event("show_upload", _, socket),
    do: {:noreply, assign(socket, :show_upload_modal, true)}

  def handle_event("hide_upload", _, socket),
    do: {:noreply, assign(socket, :show_upload_modal, false)}

  def handle_event("validate_upload", _params, socket), do: {:noreply, socket}

  def handle_event("save_upload", %{"caption" => caption}, socket) do
    scope = socket.assigns.current_scope
    bike = socket.assigns.selected_bike

    uploaded_images =
      consume_uploaded_entries(socket, :photo, fn %{path: tmp_path}, entry ->
        ext = Path.extname(entry.client_name)
        key = "riders/#{scope.user.id}/bikes/#{bike.id}/#{entry.uuid}#{ext}"

        case KoveRiders.Storage.upload_file(tmp_path, key, entry.client_type) do
          {:ok, _} ->
            url = KoveRiders.Storage.public_url(key)
            {:ok, %{r2_key: key, url: url}}

          {:error, reason} ->
            {:postpone, reason}
        end
      end)

    Enum.each(uploaded_images, fn img ->
      UserBikes.add_image(scope, bike.id, Map.put(img, :caption, caption))
    end)

    updated_bike = UserBikes.get_user_bike!(scope, bike.id)

    user_bikes =
      Enum.map(socket.assigns.user_bikes, fn b ->
        if b.id == updated_bike.id, do: updated_bike, else: b
      end)

    {:noreply,
     socket
     |> assign(:selected_bike, updated_bike)
     |> assign(:user_bikes, user_bikes)
     |> assign(:show_upload_modal, false)
     |> put_flash(:info, "Photo(s) uploaded!")}
  end

  def handle_event("delete_photo", %{"id" => id}, socket) do
    scope = socket.assigns.current_scope
    bike = socket.assigns.selected_bike
    UserBikes.delete_image(scope, String.to_integer(id))

    updated_bike = UserBikes.get_user_bike!(scope, bike.id)

    user_bikes =
      Enum.map(socket.assigns.user_bikes, fn b ->
        if b.id == updated_bike.id, do: updated_bike, else: b
      end)

    {:noreply,
     socket
     |> assign(:selected_bike, updated_bike)
     |> assign(:user_bikes, user_bikes)
     |> put_flash(:info, "Photo deleted.")}
  end

  # ── Helpers ──────────────────────────────────────────────────────────────────

  defp dollars_to_cents(%{"cost_dollars" => dollars} = params) when is_binary(dollars) do
    cents =
      case Float.parse(dollars) do
        {f, _} -> round(f * 100)
        :error -> nil
      end

    params
    |> Map.delete("cost_dollars")
    |> Map.put("cost_cents", cents)
  end

  defp dollars_to_cents(params), do: params

  defp bike_label(%UserBike{nickname: nick, year: year, model: model}) do
    if nick && nick != "", do: nick, else: "#{year} #{UserBike.model_label(model)}"
  end

  # ── Render ───────────────────────────────────────────────────────────────────

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="flex gap-6 min-h-screen">
        <%!-- Sidebar: bike list --%>
        <aside class="w-64 shrink-0 space-y-3">
          <h2 class="text-sm font-semibold uppercase tracking-wider text-base-content/50">
            My Bikes
          </h2>

          <div id="bike-list" class="space-y-2">
            <%= for ub <- @user_bikes do %>
              <button
                id={"bike-#{ub.id}"}
                phx-click="select_bike"
                phx-value-id={ub.id}
                class={[
                  "w-full text-left p-3 rounded-lg border transition",
                  if(@selected_bike && @selected_bike.id == ub.id,
                    do: "bg-primary text-primary-content border-primary",
                    else: "bg-base-200 border-base-300 hover:border-primary/50"
                  )
                ]}
              >
                <div class="font-medium text-sm">{bike_label(ub)}</div>
                <div class="text-xs opacity-60 mt-0.5">{ub.mileage} mi</div>
              </button>
            <% end %>
          </div>

          <button phx-click="show_add_bike" class="btn btn-outline btn-sm w-full gap-1">
            <.icon name="hero-plus" class="size-4" /> Add Bike
          </button>

          <%= if @selected_bike do %>
            <div class="divider my-2"></div>
            <div class="text-xs text-base-content/50">Share your page</div>
            <div class="flex items-center gap-2">
              <code class="text-xs bg-base-300 px-2 py-1 rounded flex-1 truncate">
                koveriders.com/@{@current_scope.user.handle}
              </code>
              <.link
                navigate={~p"/@#{@current_scope.user.handle}"}
                class="btn btn-xs btn-ghost"
                target="_blank"
              >
                <.icon name="hero-arrow-top-right-on-square" class="size-3" />
              </.link>
            </div>

            <label class="flex items-center gap-2 cursor-pointer">
              <input
                type="checkbox"
                class="toggle toggle-primary toggle-sm"
                checked={@selected_bike.is_public}
                phx-click="toggle_public"
              />
              <span class="text-xs">Public page</span>
            </label>
          <% end %>
        </aside>

        <%!-- Main content --%>
        <div class="flex-1 min-w-0">
          <%= if @selected_bike do %>
            <div class="space-y-6">
              <%!-- Bike header --%>
              <div class="flex items-start justify-between">
                <div>
                  <h1 class="text-2xl font-bold">{bike_label(@selected_bike)}</h1>
                  <p class="text-base-content/60">
                    {UserBike.model_label(@selected_bike.model)} · {@selected_bike.mileage} miles
                  </p>
                </div>
              </div>

              <%!-- Tabs --%>
              <div class="tabs tabs-boxed w-fit">
                <button
                  class={["tab", @active_tab == :mods && "tab-active"]}
                  phx-click="set_tab"
                  phx-value-tab="mods"
                >
                  Mods ({length(@selected_bike.mods)})
                </button>
                <button
                  class={["tab", @active_tab == :photos && "tab-active"]}
                  phx-click="set_tab"
                  phx-value-tab="photos"
                >
                  Photos ({length(@selected_bike.images)})
                </button>
              </div>

              <%!-- Mods tab --%>
              <%= if @active_tab == :mods do %>
                <div class="space-y-4">
                  <div class="flex justify-between items-center">
                    <h2 class="text-lg font-semibold">Modifications</h2>
                    <button phx-click="show_add_mod" class="btn btn-primary btn-sm gap-1">
                      <.icon name="hero-plus" class="size-4" /> Add Mod
                    </button>
                  </div>

                  <%= if @selected_bike.mods == [] do %>
                    <div class="py-12 text-center text-base-content/40">
                      <.icon name="hero-wrench-screwdriver" class="size-12 mx-auto mb-3 opacity-30" />
                      <p>No mods yet. Add your first modification!</p>
                    </div>
                  <% else %>
                    <div id="mods-list" class="grid gap-3">
                      <%= for mod <- @selected_bike.mods do %>
                        <div id={"mod-#{mod.id}"} class="card bg-base-200 shadow-sm">
                          <div class="card-body py-3 px-4 flex-row items-start justify-between gap-4">
                            <div class="flex-1 min-w-0">
                              <div class="flex items-center gap-2 flex-wrap">
                                <span class="badge badge-outline badge-sm">{mod.category}</span>
                                <span class="font-medium">{mod.title}</span>
                                <%= if mod.brand do %>
                                  <span class="text-sm text-base-content/50">by {mod.brand}</span>
                                <% end %>
                              </div>
                              <%= if mod.description do %>
                                <p class="text-sm text-base-content/60 mt-1">{mod.description}</p>
                              <% end %>
                              <div class="flex gap-4 mt-1 text-xs text-base-content/50">
                                <%= if mod.cost_cents do %>
                                  <span>{Currency.format(mod.cost_cents)}</span>
                                <% end %>
                                <%= if mod.rating do %>
                                  <span>
                                    {"★" |> String.duplicate(mod.rating)}{"☆"
                                    |> String.duplicate(5 - mod.rating)}
                                  </span>
                                <% end %>
                              </div>
                            </div>
                            <div class="flex gap-1 shrink-0">
                              <button
                                phx-click="show_edit_mod"
                                phx-value-id={mod.id}
                                class="btn btn-ghost btn-xs"
                              >
                                <.icon name="hero-pencil" class="size-3" />
                              </button>
                              <button
                                phx-click="delete_mod"
                                phx-value-id={mod.id}
                                class="btn btn-ghost btn-xs text-error"
                                data-confirm="Delete this mod?"
                              >
                                <.icon name="hero-trash" class="size-3" />
                              </button>
                            </div>
                          </div>
                        </div>
                      <% end %>
                    </div>
                  <% end %>
                </div>
              <% end %>

              <%!-- Photos tab --%>
              <%= if @active_tab == :photos do %>
                <div class="space-y-4">
                  <div class="flex justify-between items-center">
                    <h2 class="text-lg font-semibold">Photos</h2>
                    <button phx-click="show_upload" class="btn btn-primary btn-sm gap-1">
                      <.icon name="hero-camera" class="size-4" /> Upload
                    </button>
                  </div>

                  <%= if @selected_bike.images == [] do %>
                    <div class="py-12 text-center text-base-content/40">
                      <.icon name="hero-photo" class="size-12 mx-auto mb-3 opacity-30" />
                      <p>No photos yet. Upload your first shot!</p>
                    </div>
                  <% else %>
                    <div id="photos-grid" class="grid grid-cols-2 md:grid-cols-3 gap-3">
                      <%= for img <- @selected_bike.images do %>
                        <div
                          id={"img-#{img.id}"}
                          class="relative group aspect-square rounded-lg overflow-hidden bg-base-300"
                        >
                          <img
                            src={img.url}
                            alt={img.caption || "Bike photo"}
                            class="w-full h-full object-cover"
                          />
                          <div class="absolute inset-0 bg-black/50 opacity-0 group-hover:opacity-100 transition flex items-center justify-center">
                            <button
                              phx-click="delete_photo"
                              phx-value-id={img.id}
                              class="btn btn-error btn-sm"
                              data-confirm="Delete this photo?"
                            >
                              <.icon name="hero-trash" class="size-4" />
                            </button>
                          </div>
                          <%= if img.caption do %>
                            <div class="absolute bottom-0 left-0 right-0 bg-black/60 text-white text-xs p-1 truncate">
                              {img.caption}
                            </div>
                          <% end %>
                        </div>
                      <% end %>
                    </div>
                  <% end %>
                </div>
              <% end %>
            </div>
          <% else %>
            <div class="py-20 text-center text-base-content/40 space-y-4">
              <.icon name="hero-wrench-screwdriver" class="size-16 mx-auto opacity-30" />
              <p class="text-lg">Your garage is empty.</p>
              <button phx-click="show_add_bike" class="btn btn-primary">Add your first bike</button>
            </div>
          <% end %>
        </div>
      </div>

      <%!-- Add Bike Modal --%>
      <%= if @show_add_bike_modal do %>
        <div class="modal modal-open">
          <div class="modal-box space-y-4">
            <h3 class="font-bold text-lg">Add a bike to your garage</h3>
            <.form
              for={@add_bike_form}
              id="add-bike-form"
              phx-change="validate_add_bike"
              phx-submit="add_bike"
            >
              <div class="space-y-3">
                <.input
                  field={@add_bike_form[:year]}
                  type="number"
                  label="Year"
                  min="2020"
                  max="2030"
                />
                <.input
                  field={@add_bike_form[:model]}
                  type="select"
                  label="Model"
                  options={[{"Select a model…", ""}] ++ UserBike.models()}
                />
                <.input
                  field={@add_bike_form[:mileage]}
                  type="number"
                  label="Mileage (miles)"
                  min="0"
                />
                <.input field={@add_bike_form[:nickname]} type="text" label="Nickname (optional)" />
              </div>
              <div class="modal-action">
                <button type="button" phx-click="hide_add_bike" class="btn btn-ghost">Cancel</button>
                <.button type="submit" class="btn btn-primary">Add to Garage</.button>
              </div>
            </.form>
          </div>
          <div class="modal-backdrop" phx-click="hide_add_bike"></div>
        </div>
      <% end %>

      <%!-- Add/Edit Mod Modal --%>
      <%= if @show_add_mod_modal do %>
        <div class="modal modal-open">
          <div class="modal-box space-y-4">
            <h3 class="font-bold text-lg">
              {if @editing_mod, do: "Edit Mod", else: "Add Mod"}
            </h3>
            <.form for={@mod_form} id="mod-form" phx-change="validate_mod" phx-submit="save_mod">
              <div class="space-y-3">
                <div class="form-control">
                  <label class="label"><span class="label-text">Category</span></label>
                  <select
                    name="user_bike_mod[category]"
                    class="select select-bordered w-full"
                    required
                  >
                    <option value="">Select category…</option>
                    <%= for cat <- UserBikeMod.categories() do %>
                      <option value={cat} selected={@mod_form[:category].value == cat}>
                        {String.capitalize(cat)}
                      </option>
                    <% end %>
                  </select>
                </div>
                <.input field={@mod_form[:title]} type="text" label="Title" required />
                <.input field={@mod_form[:brand]} type="text" label="Brand" />
                <.input field={@mod_form[:description]} type="textarea" label="Notes" />
                <div class="form-control">
                  <label class="label"><span class="label-text">Cost (USD)</span></label>
                  <input
                    type="number"
                    name="user_bike_mod[cost_dollars]"
                    class="input input-bordered"
                    min="0"
                    step="0.01"
                    placeholder="0.00"
                    value={
                      if @mod_form[:cost_cents].value,
                        do: @mod_form[:cost_cents].value / 100,
                        else: ""
                    }
                  />
                </div>
                <div class="form-control">
                  <label class="label"><span class="label-text">Rating</span></label>
                  <select name="user_bike_mod[rating]" class="select select-bordered w-full">
                    <option value="">No rating</option>
                    <%= for r <- 1..5 do %>
                      <option value={r} selected={@mod_form[:rating].value == r}>
                        {"★" |> String.duplicate(r)} ({r}/5)
                      </option>
                    <% end %>
                  </select>
                </div>
              </div>
              <div class="modal-action">
                <button type="button" phx-click="hide_mod_modal" class="btn btn-ghost">Cancel</button>
                <.button type="submit" class="btn btn-primary">Save Mod</.button>
              </div>
            </.form>
          </div>
          <div class="modal-backdrop" phx-click="hide_mod_modal"></div>
        </div>
      <% end %>

      <%!-- Upload Photos Modal --%>
      <%= if @show_upload_modal do %>
        <div class="modal modal-open">
          <div class="modal-box space-y-4">
            <h3 class="font-bold text-lg">Upload Photos</h3>
            <.form for={%{}} id="upload-form" phx-change="validate_upload" phx-submit="save_upload">
              <div class="space-y-3">
                <div
                  class="border-2 border-dashed border-base-300 rounded-lg p-6 text-center cursor-pointer hover:border-primary/50"
                  phx-drop-target={@uploads.photo.ref}
                >
                  <label for={@uploads.photo.ref} class="text-primary cursor-pointer hover:underline">
                    <.live_file_input upload={@uploads.photo} class="hidden" />
                    <.icon name="hero-arrow-up-tray" class="size-8 mx-auto mb-2 opacity-40" />
                    <p class="text-sm text-base-content/50">
                      Drag photos here or
                      browse
                    </p>
                    <p class="text-xs text-base-content/30 mt-1">JPG, PNG, WebP · max 10 MB each</p>
                  </label>
                </div>

                <%= for entry <- @uploads.photo.entries do %>
                  <div class="flex items-center gap-3">
                    <.live_img_preview entry={entry} class="size-12 rounded object-cover" />
                    <div class="flex-1 min-w-0">
                      <p class="text-sm truncate">{entry.client_name}</p>
                      <progress
                        class="progress progress-primary w-full"
                        value={entry.progress}
                        max="100"
                      >
                      </progress>
                    </div>
                    <button
                      type="button"
                      phx-click="cancel-upload"
                      phx-value-ref={entry.ref}
                      class="btn btn-ghost btn-xs"
                    >
                      <.icon name="hero-x-mark" class="size-3" />
                    </button>
                  </div>
                  <%= for err <- upload_errors(@uploads.photo, entry) do %>
                    <p class="text-error text-xs">{err}</p>
                  <% end %>
                <% end %>

                <input
                  type="text"
                  name="caption"
                  class="input input-bordered input-sm w-full"
                  placeholder="Caption (optional)"
                />
              </div>
              <div class="modal-action">
                <button type="button" phx-click="hide_upload" class="btn btn-ghost">Cancel</button>
                <.button type="submit" class="btn btn-primary" disabled={@uploads.photo.entries == []}>
                  Upload
                </.button>
              </div>
            </.form>
          </div>
          <div class="modal-backdrop" phx-click="hide_upload"></div>
        </div>
      <% end %>
    </Layouts.app>
    """
  end
end
