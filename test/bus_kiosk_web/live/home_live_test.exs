defmodule BusKioskWeb.HomeLiveTest do
  use BusKioskWeb.ConnCase
  import Phoenix.LiveViewTest
  @endpoint BusKioskWeb.Endpoint

  test "GET /", %{conn: conn} do
    conn = get(conn, "/")
    assert html_response(conn, 200) =~ "Get Buses!"
    {:ok, _view, _html} = live(conn)
  end
end
