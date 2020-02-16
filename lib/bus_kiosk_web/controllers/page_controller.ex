defmodule BusKioskWeb.PageController do
  use BusKioskWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
