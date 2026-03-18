defmodule KoveRidersWeb.RiderPageLiveTest do
  use KoveRidersWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  describe "/@:handle" do
    test "renders rider page with handle and bikes", %{conn: conn} do
      user = insert(:user, handle: "testpilot")
      insert(:user_bike, user: user, model: "800x_pro", year: 2024, is_public: true)

      {:ok, view, _html} = live(conn, ~p"/@testpilot")

      assert has_element?(view, "[id^='ub-']")
      assert render(view) =~ "testpilot"
    end

    test "redirects to home when handle not found", %{conn: conn} do
      assert {:error, {:live_redirect, %{to: "/"}}} = live(conn, ~p"/@nobody_here_xyz")
    end

    test "renders empty state when rider has no public bikes", %{conn: conn} do
      insert(:user, handle: "emptyrider")
      {:ok, view, _html} = live(conn, ~p"/@emptyrider")
      assert render(view) =~ "emptyrider"
      refute has_element?(view, "[id^='ub-']")
    end
  end
end
