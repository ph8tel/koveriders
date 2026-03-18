defmodule KoveRidersWeb.GarageLive.UploadErrorTest do
  use KoveRidersWeb.ConnCase, async: false

  import Phoenix.LiveViewTest
  import Mox

  setup :verify_on_exit!

  setup do
    Application.put_env(:kove_riders, :storage_adapter, KoveRiders.MockStorage)

    on_exit(fn ->
      Application.put_env(:kove_riders, :storage_adapter, KoveRiders.Storage.Local)
    end)

    :ok
  end

  @fixture Path.join([__DIR__, "../../support/fixtures/test-photo.jpg"])

  test "shows flash error when storage upload fails", %{conn: conn} do
    user = insert(:user)
    bike = insert(:user_bike, user: user)
    conn = log_in_user(conn, user)

    KoveRiders.MockStorage
    |> expect(:upload_file, fn _path, _key, _type ->
      {:error, "R2 is down"}
    end)

    {:ok, view, _html} = live(conn, ~p"/garage/#{bike.id}")

    # Switch to Photos tab first
    view |> element("[phx-value-tab='photos']") |> render_click()

    view |> element("[phx-click='show_upload']") |> render_click()

    photo_input =
      file_input(view, "#upload-form", :photo, [
        %{
          name: "test-photo.jpg",
          content: File.read!(@fixture),
          type: "image/jpeg"
        }
      ])

    render_upload(photo_input, "test-photo.jpg")

    view
    |> form("#upload-form", %{caption: ""})
    |> render_submit()

    assert render(view) =~ "R2 is down"
    refute has_element?(view, "[id^='img-']")
  end
end
