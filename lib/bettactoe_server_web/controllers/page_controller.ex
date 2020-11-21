defmodule BettactoeServerWeb.PageController do
  use BettactoeServerWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
