defmodule BusKioskWeb.KioskView do
  use BusKioskWeb, :view
  alias BusKiosk.RealTimePrediction, as: Prediction

  def format_only_time(%NaiveDateTime{} = dt) do
    am_pm = am_pm(dt.hour)

    hour =
      cond do
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

  def format_predicted_time(%Prediction{} = prediction) do
    time = format_only_time(prediction.predicted_time)

    if prediction.vehicle_id == "" do
      "#{time}"
    else
      # bus emoji
      "#{time} " <> <<0xF0, 0x9F, 0x9A, 0x8D>>
    end
  end

  def format_arrival(%Prediction{} = prediction) do
    case prediction.prediction_countdown_minutes do
      "DLY" ->
        "Delayed"

      "DUE" ->
        "1m"

      minutes ->
        "#{minutes}m"
    end
  end

  def am_pm(hour) when hour < 12, do: "AM"
  def am_pm(_hour), do: "PM"

  def stop_name(stop_id, []), do: stop_id

  def stop_name(stop_id, [prediction | _]) do
    name =
      prediction.stop_name
      |> String.replace(~r/\bSTREET\b/, "ST")
      |> String.replace(~r/\bAVENUE\b/, "AV")
      |> String.replace(~r/\bDRIVE\b/, "DR")
      |> String.replace(~r/\bROAD\b/, "RD")

    "#{name} (#{stop_id})"
  end
end
