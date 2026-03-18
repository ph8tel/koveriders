defmodule KoveRidersWeb.ConnCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a connection.

  Such tests rely on `Phoenix.ConnTest` and also
  import other functionality to make it easier
  to build common data structures and query the data layer.

  Finally, if the test case interacts with the database,
  we enable the SQL sandbox, so changes done to the database
  are reverted at the end of every test. If you are using
  PostgreSQL, you can even run database tests asynchronously
  by setting `use KoveRidersWeb.ConnCase, async: true`, although
  this option is not recommended for other databases.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      # The default endpoint for testing
      @endpoint KoveRidersWeb.Endpoint

      use KoveRidersWeb, :verified_routes

      # Import conveniences for testing with connections
      import Plug.Conn
      import Phoenix.ConnTest
      import KoveRidersWeb.ConnCase
      import KoveRiders.Factory
    end
  end

  setup tags do
    KoveRiders.DataCase.setup_sandbox(tags)
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end

  @doc """
  Sets up the connection for an authenticated user.

  Injects the user's session token so that LiveViews and plugs
  that call `UserAuth.mount_current_scope` or `UserAuth.fetch_current_scope_for_user`
  will see a logged-in user.
  """
  def log_in_user(conn, user) do
    token = KoveRiders.Accounts.generate_user_session_token(user)

    conn
    |> Phoenix.ConnTest.init_test_session(%{})
    |> Plug.Conn.put_session(:user_token, token)
  end
end
