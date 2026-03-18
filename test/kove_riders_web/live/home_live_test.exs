defmodule KoveRidersWeb.HomeLiveTest do
  use KoveRidersWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  test "renders home page for guest", %{conn: conn} do
    {:ok, _view, html} = live(conn, ~p"/")
    assert html =~ "KoveRiders"
  end

  test "renders home page for authenticated user", %{conn: conn} do
    user = insert(:user)
    conn = log_in_user(conn, user)
    {:ok, _view, html} = live(conn, ~p"/")
    assert html =~ user.handle || html =~ "garage"
  end
end
