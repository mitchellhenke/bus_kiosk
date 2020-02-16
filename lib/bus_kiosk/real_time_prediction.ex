defmodule BusKiosk.RealTimePrediction do
  import NimbleParsec

  defstruct [
    :destination,
    :delayed,
    :distance_to_stop,
    :prediction_countdown_minutes,
    :predicted_time,
    :route,
    :route_display,
    :route_direction,
    :stop_id,
    :stop_name,
    :trip_block_id,
    :trip_id,
    :timestamp,
    :vehicle_id
  ]

  defparsec(
    :parse_datetime,
    integer(4)
    |> integer(2)
    |> integer(2)
    |> ignore(string(" "))
    |> integer(2)
    |> ignore(string(":"))
    |> integer(2)
    |> ignore(string(":"))
    |> integer(2)
  )

  def from_json(json) when is_map(json) do
    with {:ok, destination} <- Map.fetch(json, "des"),
         {:ok, delayed} <- Map.fetch(json, "dly"),
         {:ok, distance_to_stop} <- Map.fetch(json, "dstp"),
         {:ok, prediction_countdown_minutes} <- Map.fetch(json, "prdctdn"),
         {:ok, predicted_time} <- Map.fetch(json, "prdtm"),
         {:ok, predicted_time} <- parse_timestamp(predicted_time),
         {:ok, route} <- Map.fetch(json, "rt"),
         {:ok, route_display} <- Map.fetch(json, "rtdd"),
         {:ok, route_direction} <- Map.fetch(json, "rtdir"),
         {:ok, stop_id} <- Map.fetch(json, "stpid"),
         {:ok, stop_name} <- Map.fetch(json, "stpnm"),
         {:ok, trip_block_id} <- Map.fetch(json, "tablockid"),
         {:ok, trip_id} <- Map.fetch(json, "tatripid"),
         {:ok, timestamp} <- Map.fetch(json, "tmstmp"),
         {:ok, timestamp} <- parse_timestamp(timestamp),
         {:ok, vehicle_id} <- Map.fetch(json, "vid") do
      {:ok,
       %__MODULE__{
         destination: destination,
         delayed: delayed,
         distance_to_stop: distance_to_stop,
         prediction_countdown_minutes: prediction_countdown_minutes,
         predicted_time: predicted_time,
         route: route,
         route_display: route_display,
         route_direction: route_direction,
         stop_id: stop_id,
         stop_name: stop_name,
         trip_block_id: trip_block_id,
         trip_id: trip_id,
         timestamp: timestamp,
         vehicle_id: vehicle_id
       }}
    end
  end

  def parse_timestamp(timestamp) do
    with {:ok, [year, month, day, hour, minute, second], _, _, _, _} <- parse_datetime(timestamp) do
      NaiveDateTime.new(year, month, day, hour, minute, second)
    end
  end

  # "des" => "KK/Mitchell",
  # "dly" => false,
  # "dstp" => 0,
  # "dyn" => 0,
  # "prdctdn" => "86",
  # "prdtm" => "20200209 13:54:49",
  # "rt" => "52",
  # "rtdd" => "52",
  # "rtdir" => "NORTH",
  # "stpid" => "1311",
  # "stpnm" => "KINNICKINNIC + OTJEN",
  # "tablockid" => "52 -101",
  # "tatripid" => "31943731",
  # "tmstmp" => "20200209 12:28:18",
  # "typ" => "A",
  # "vid" => "",
  # "zone" => ""
end
