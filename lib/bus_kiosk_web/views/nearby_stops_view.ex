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
end
