defmodule BusKiosk.RealTime do
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

          _ ->
            {:halt, :error}
        end
      end)
    end
  end
end
