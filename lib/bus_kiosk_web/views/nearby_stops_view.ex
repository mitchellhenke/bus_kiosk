defmodule BusKioskWeb.NearbyStopsView do
  use BusKioskWeb, :view

  def azimuth_emoji(nil) do
    ""
  end

  def azimuth_emoji(azimuth) do
    " #{do_azimuth_emoji(azimuth)}"
  end

  # north
  def do_azimuth_emoji(azimuth) when azimuth >= 337.5 or azimuth < 22.5 do
    <<226, 172, 134, 239, 184, 143>>
  end

  # north-east
  def do_azimuth_emoji(azimuth) when azimuth >= 22.5 and azimuth < 67.5 do
    <<226, 134, 151, 239, 184, 143>>
  end

  # east
  def do_azimuth_emoji(azimuth) when azimuth >= 67.5 and azimuth < 112.5 do
    <<226, 158, 161, 239, 184, 143>>
  end

  # south-east
  def do_azimuth_emoji(azimuth) when azimuth >= 112.5 and azimuth < 157.5 do
    <<226, 134, 152, 239, 184, 143>>
  end

  # south
  def do_azimuth_emoji(azimuth) when azimuth >= 157.5 and azimuth < 202.5 do
    <<226, 172, 135, 239, 184, 143>>
  end

  # south-west
  def do_azimuth_emoji(azimuth) when azimuth >= 202.5 and azimuth < 247.5 do
    <<226, 134, 153, 239, 184, 143>>
  end

  # west
  def do_azimuth_emoji(azimuth) when azimuth >= 247.5 and azimuth < 292.5 do
    <<226, 172, 133, 239, 184, 143>>
  end

  # north-west
  def do_azimuth_emoji(azimuth) when azimuth >= 292.5 and azimuth < 337.5 do
    <<226, 134, 150, 239, 184, 143>>
  end

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
