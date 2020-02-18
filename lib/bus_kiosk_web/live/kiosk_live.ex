defmodule BusKioskWeb.KioskLive do
  use Phoenix.LiveView

  defmodule Params do
    defstruct [:stop_ids]

    def change(params) do
      types = %{
        stop_ids: {:array, :integer},
        routes: {:array, :string},
        limit: :integer
      }

      data = %Params{}

      {data, types}
      |> Ecto.Changeset.cast(params, [:stop_ids, :limit, :routes])
      |> Ecto.Changeset.validate_required([:stop_ids])
      |> Ecto.Changeset.validate_length(:stop_ids, min: 1, max: 4)
      |> Ecto.Changeset.validate_length(:routes, min: 0, max: 99)
      |> Ecto.Changeset.validate_number(:limit, greater_than: 0, less_than: 100)
    end
  end

  def mount(params, _session, socket) do
    title = Map.get(params, "title")
    location = Map.get(params, "location")

    params =
      Map.update(params, "stop_ids", nil, fn stop_ids ->
        String.split(stop_ids, ",")
      end)
      |> Map.update("routes", nil, fn routes ->
        String.split(routes, ",")
      end)

    changeset = Params.change(params)

    socket =
      case Ecto.Changeset.apply_action(changeset, :insert) do
        {:ok, params} ->
          stop_prediction_map =
            Enum.reduce(params.stop_ids, %{}, fn stop_id, map ->
              Map.put(map, "#{stop_id}", [])
            end)

          socket =
            assign(socket, :stop_prediction_map, stop_prediction_map)
            |> assign(:stop_ids, params.stop_ids)
            |> assign(:params, params)
            |> assign(:valid, true)
            |> assign(:title, title)
            |> assign(:location, location)
            |> assign(:predictions, [])

          Process.send_after(self(), :subscribe, 0)
          socket

        {:error, _cs} ->
          assign(socket, :valid, false)
      end

    {:ok, socket}
  end

  def handle_info(:subscribe, socket) do
    BusKiosk.RealTimePoller.subscribe(socket.assigns.stop_ids)
    {:noreply, socket}
  end

  def handle_info({:bus_predictions, stop_id, predictions}, socket) do
    routes = Map.get(socket.assigns.params, :routes)
    limit = Map.get(socket.assigns.params, :limit)

    predictions = filter_predictions(predictions, routes, limit)

    map = Map.put(socket.assigns.stop_prediction_map, stop_id, predictions)
    socket = assign(socket, :stop_prediction_map, map)
    {:noreply, socket}
  end

  def handle_info(_message, socket) do
    {:noreply, socket}
  end

  def render(assigns) do
    if assigns.valid do
      Phoenix.View.render(BusKioskWeb.KioskView, "page.html", assigns)
    else
      ~L"""
      <div>
        Invalid parameters
      </div>
      """
    end
  end

  defp filter_predictions(predictions, nil, nil), do: predictions
  defp filter_predictions(predictions, nil, limit), do: Enum.take(predictions, limit)

  defp filter_predictions(predictions, routes, nil) do
    Enum.filter(predictions, fn prediction ->
      Enum.member?(routes, prediction.route)
    end)
  end

  defp filter_predictions(predictions, routes, limit) do
    Enum.filter(predictions, fn prediction ->
      Enum.member?(routes, prediction.route)
    end)
    |> Enum.take(limit)
  end
end
