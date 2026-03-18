defmodule KoveRidersWeb.UserLive.SettingsTest do
  use KoveRidersWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  describe "handle update" do
    test "changes handle successfully", %{conn: conn} do
      user = insert(:user, handle: "original_handle", handle_change_count: 0)
      conn = log_in_user(conn, user)

      {:ok, view, _html} = live(conn, ~p"/users/settings")

      assert has_element?(view, "#handle-form")

      view
      |> form("#handle-form", user: %{handle: "brand_new_handle"})
      |> render_submit()

      assert render(view) =~ "Handle updated to @brand_new_handle"
    end

    test "shows validation error for invalid handle", %{conn: conn} do
      user = insert(:user)
      conn = log_in_user(conn, user)

      {:ok, view, _html} = live(conn, ~p"/users/settings")

      view
      |> form("#handle-form", user: %{handle: "INVALID HANDLE!!!"})
      |> render_submit()

      assert has_element?(view, "#handle-form")
      assert render(view) =~ "only lowercase"
    end

    test "shows locked alert when handle limit is reached", %{conn: conn} do
      user = insert(:user, handle_change_count: 2)
      conn = log_in_user(conn, user)

      {:ok, view, _html} = live(conn, ~p"/users/settings")

      # Form is hidden when locked; the template shows an alert instead
      assert render(view) =~ "all your handle changes"
      refute has_element?(view, "#handle-form")
    end

    test "unauthenticated user is redirected", %{conn: conn} do
      assert {:error, {:redirect, %{to: "/users/log-in"}}} =
               live(conn, ~p"/users/settings")
    end
  end
end
