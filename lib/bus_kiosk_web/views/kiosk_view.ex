defmodule BusKioskWeb.KioskView do
  use BusKioskWeb, :view

  def format_only_time(%NaiveDateTime{} = dt) do
    am_pm = am_pm(dt.hour)

    hour = cond do
      dt.hour == 0 ->
        12
      dt.hour >= 13 ->
        dt.hour - 12
      true ->
        dt.hour
    end

    hour = String.pad_leading("#{hour}", 2, "0")
    minute = String.pad_leading("#{dt.minute}", 2, "0")
    second = String.pad_leading("#{dt.second}", 2, "0")

    "#{hour}:#{minute}:#{second} #{am_pm}"
  end

  def am_pm(hour) when hour < 12, do: "AM"
  def am_pm(_hour), do: "PM"

  def url_qr_code do
    Routes.live_url(BusKioskWeb.Endpoint, BusKioskWeb.KioskLive, %{})
    |> EQRCode.encode()
    |> EQRCode.svg()
  end
end
