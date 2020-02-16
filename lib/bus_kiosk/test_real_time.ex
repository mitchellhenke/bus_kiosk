defmodule BusKiosk.TestRealTime do
  @moduledoc """
  This is the same interface as BusKiosk.RealTime, but returns an example
  JSON response instead of from live HTTP API.
  """

  def get_predictions(_stop_ids) do
    with body <- File.read!("./priv/data/example.json"),
         {:ok, body} <- Jason.decode(body),
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
