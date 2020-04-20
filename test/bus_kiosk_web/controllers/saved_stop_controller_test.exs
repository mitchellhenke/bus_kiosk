defmodule BusKioskWeb.SavedStopControllerTest do
  use BusKioskWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, "/saved_stops")
    assert html_response(conn, 200) =~ "My Saved Stops"
  end
end
