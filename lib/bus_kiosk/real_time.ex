defmodule BusKiosk.RealTime do
  require Logger
  @base_url "http://realtime.ridemcts.com/bustime/api/v3"

  def get_predictions(stop_ids) do
    stop_ids = Enum.join(stop_ids, ",")
    route = "/getpredictions"
    key = Application.fetch_env!(:bus_kiosk, :mcts_api_key)

    params =
      %{stpid: stop_ids, tmres: "s", key: key, format: "json"}
      |> URI.encode_query()

    url = "#{@base_url}#{route}?#{params}"

    with {:ok, response} <- Mojito.request(method: :get, url: url),
         {:ok, body} <- Jason.decode(response.body),
         {:ok, resp} <- Map.fetch(body, "bustime-response"),
         {:ok, predictions} <- Map.fetch(resp, "prd") do
      Enum.reduce_while(predictions, {:ok, []}, fn prediction, {:ok, list} ->
        case BusKiosk.RealTimePrediction.from_json(prediction) do
          {:ok, prediction} ->
            {:cont, {:ok, [prediction | list]}}

          e ->
            Logger.error("Error getting predictions #{inspect(e)}")
            {:halt, :error}
        end
      end)
    end
  end

  def get_directions_map do
    %{
      "12" => %{"0" => "East", "1" => "West"},

      "137" => %{"0" => "West", "1" => "East"},

      "14" => %{"0" => "North", "1" => "South"},
      "143" => %{"0" => "North", "1" => "South"},
      "15" => %{"0" => "North", "1" => "South"},
      "19" => %{"0" => "North", "1" => "South"},
      "21" => %{"0" => "East", "1" => "West"},
      "22" => %{"0" => "East", "1" => "West"},
      "28" => %{"0" => "North", "1" => "South"},
      "30" => %{"0" => "East", "1" => "West"},
      "31" => %{"0" => "East", "1" => "West"},
      "33" => %{"0" => "East", "1" => "West"},
      "35" => %{"0" => "North", "1" => "South"},
      "40" => %{"0" => "North", "1" => "South"},
      "40U" => %{"0" => "North", "1" => "South"},
      "43" => %{"0" => "East", "1" => "West"},
      "44" => %{"0" => "East", "1" => "West"},
      "44U" => %{"0" => "East", "1" => "West"},
      "46" => %{"0" => "East", "1" => "West"},
      "48" => %{"0" => "North", "1" => "South"},
      "49" => %{"0" => "North", "1" => "South"},
      "49U" => %{"0" => "South", "1" => "North"},
      "51" => %{"0" => "East", "1" => "West"},
      "52" => %{"0" => "North", "1" => "South"},
      "53" => %{"0" => "East", "1" => "West"},
      "54" => %{"0" => "East", "1" => "West"},
      "55" => %{"0" => "East", "1" => "West"},
      "56" => %{"0" => "East", "1" => "West"},
      "57" => %{"0" => "East", "1" => "West"},
      "60" => %{"0" => "East", "1" => "West"},
      "63" => %{"0" => "East", "1" => "West"},
      "64" => %{"0" => "North", "1" => "South"},
      "67" => %{"0" => "North", "1" => "South"},
      "76" => %{"0" => "North", "1" => "South"},
      "79" => %{"0" => "East", "1" => "West"},
      "80" => %{"0" => "North", "1" => "South"},
      "BLU" => %{"0" => "North", "1" => "South"},
      "GOL" => %{"0" => "East", "1" => "West"},
      "GRE" => %{"0" => "North", "1" => "South"},
      "PUR" => %{"0" => "North", "1" => "South"},
      "RED" => %{"0" => "East", "1" => "West"},
      "RR1" => %{"0" => "North", "1" => "South"},
      "RR2" => %{"0" => "North", "1" => "South"},
      "RR3" => %{"0" => "North", "1" => "South"},
    }
  end
end
