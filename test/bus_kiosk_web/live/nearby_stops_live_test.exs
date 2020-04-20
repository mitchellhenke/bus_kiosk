defmodule BusKioskWeb.NearbyStopsLiveTest do
  use BusKioskWeb.ConnCase
  import Phoenix.LiveViewTest
  @endpoint BusKioskWeb.Endpoint

  test "GET /nearby_stops", %{conn: conn} do
    conn = get(conn, "/nearby_stops")
    assert html_response(conn, 200) =~ "Nearby Stops"
    {:ok, _view, _html} = live(conn)
  end
end
