defmodule BusKioskWeb.NearbyStopsView do
  use BusKioskWeb, :view

  def stop_route_ids(route_ids) do
    map = BusKiosk.RealTime.get_directions_map()
    # ["GOL,1", "30,0"]
    Enum.map(route_ids, fn route_id ->
      # ["GOL", "1"]
      [route_id, direction_id] = String.split(route_id, ",")
      direction = get_in(map, [String.trim_trailing(route_id, "D"), direction_id])

      "#{route_id} - #{direction}"
    end)
    |> Enum.join(", ")

    # GOL - East-bound, 30X - West-bound
  end
end
