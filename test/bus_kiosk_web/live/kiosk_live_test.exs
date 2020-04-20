defmodule BusKioskWeb.KioskLiveTest do
  use BusKioskWeb.ConnCase
  import Phoenix.LiveViewTest
  @endpoint BusKioskWeb.Endpoint

  test "GET /live with no parameters shows error", %{conn: conn} do
    conn = get(conn, "/live")
    assert html_response(conn, 200) =~ "Oops"

    {:ok, _view, _html} = live(conn)
  end

  test "GET /live with parameters renders some stuff", %{conn: conn} do
    conn = get(conn, "/live", stop_ids: "123456,987654")
    assert html_response(conn, 200) =~ "123456"
    assert html_response(conn, 200) =~ "987654"

    {:ok, _view, _html} = live(conn)
  end
end
