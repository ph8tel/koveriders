defmodule KoveRidersWeb.PageController do
  use KoveRidersWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
