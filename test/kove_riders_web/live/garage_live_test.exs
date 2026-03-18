defmodule KoveRidersWeb.GarageLiveTest do
  use KoveRidersWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  describe "garage index — no bikes" do
    test "renders empty state for authenticated user", %{conn: conn} do
      user = insert(:user)
      conn = log_in_user(conn, user)

      {:ok, _view, html} = live(conn, ~p"/garage")
      assert html =~ "garage" or html =~ "bike"
    end

    test "unauthenticated user is redirected", %{conn: conn} do
      assert {:error, {:redirect, %{to: "/users/log-in"}}} = live(conn, ~p"/garage")
    end
  end

  describe "add bike" do
    test "creates a bike and shows it in the list", %{conn: conn} do
      user = insert(:user)
      conn = log_in_user(conn, user)

      {:ok, view, _html} = live(conn, ~p"/garage")

      view |> element("button", "Add Bike") |> render_click()

      assert has_element?(view, "#add-bike-form")

      view
      |> form("#add-bike-form", user_bike: %{model: "800x_pro", year: "2024"})
      |> render_submit()

      assert has_element?(view, "[id^='bike-']")
    end

    test "shows validation error for missing year", %{conn: conn} do
      user = insert(:user)
      conn = log_in_user(conn, user)

      {:ok, view, _html} = live(conn, ~p"/garage")

      view |> element("button", "Add Bike") |> render_click()

      view
      |> form("#add-bike-form", user_bike: %{model: "800x_pro", year: ""})
      |> render_submit()

      # form should still be present (not closed on error)
      assert has_element?(view, "#add-bike-form")
    end
  end

  describe "bike detail — mods" do
    test "can add and delete a mod", %{conn: conn} do
      user = insert(:user)
      bike = insert(:user_bike, user: user)
      conn = log_in_user(conn, user)

      {:ok, view, _html} = live(conn, ~p"/garage/#{bike.id}")

      # Switch to mods tab
      view |> element("[phx-value-tab='mods']") |> render_click()

      # Open mod form
      view |> element("button", "Add Mod") |> render_click()

      assert has_element?(view, "#mod-form")

      view
      |> form("#mod-form",
        user_bike_mod: %{category: "exhaust", title: "Akrapovic slip-on"}
      )
      |> render_submit()

      assert has_element?(view, "[id^='mod-']")
      assert render(view) =~ "Akrapovic slip-on"

      # Delete it
      mod_el = view |> element("[id^='mod-'] [phx-click='delete_mod']")
      render_click(mod_el)

      refute render(view) =~ "Akrapovic slip-on"
    end
  end

  describe "bike detail — photo upload" do
    @fixture Path.join([__DIR__, "../../support/fixtures/test-photo.jpg"])

    test "uploads a photo via Local adapter", %{conn: conn} do
      user = insert(:user)
      bike = insert(:user_bike, user: user)
      conn = log_in_user(conn, user)

      {:ok, view, _html} = live(conn, ~p"/garage/#{bike.id}")

      # Switch to Photos tab first (upload button lives there)
      view |> element("[phx-value-tab='photos']") |> render_click()

      # Open upload panel
      view |> element("[phx-click='show_upload']") |> render_click()

      assert has_element?(view, "#upload-form")

      photo_input =
        file_input(view, "#upload-form", :photo, [
          %{
            name: "test-photo.jpg",
            content: File.read!(@fixture),
            type: "image/jpeg"
          }
        ])

      assert render_upload(photo_input, "test-photo.jpg") =~ "test-photo.jpg"

      view
      |> form("#upload-form", %{caption: "My first photo"})
      |> render_submit()

      assert has_element?(view, "[id^='img-']")
    end
  end
end
