defmodule BusKioskWeb.KioskLive do
  use Phoenix.LiveView
  alias BusKioskWeb.KioskView

  defmodule Params do
    defstruct [:stop_ids]

    def change(params) do
      types = %{
        stop_ids: {:array, :string},
        route_ids: {:array, :string},
        limit: :integer
      }

      data = %Params{}

      {data, types}
      |> Ecto.Changeset.cast(params, [:stop_ids, :limit, :route_ids])
      |> Ecto.Changeset.validate_required([:stop_ids])
      |> Ecto.Changeset.validate_length(:stop_ids, min: 1, max: 4)
      |> Ecto.Changeset.validate_length(:route_ids, min: 0, max: 99)
      |> Ecto.Changeset.validate_number(:limit, greater_than: 0, less_than: 100)
    end
  end

  def mount(params, _session, socket) do
    title = Map.get(params, "title")
    location = Map.get(params, "location")

    params =
      Map.update(params, "stop_ids", nil, fn stop_ids ->
        String.trim_trailing(stop_ids, ",")
        |> String.replace(" ", "")
        |> String.split(",")
      end)
      |> Map.update("route_ids", nil, fn route_ids ->
        String.trim_trailing(route_ids, ",")
        |> String.split(",")
      end)

    changeset = Params.change(params)

    socket =
      case Ecto.Changeset.apply_action(changeset, :insert) do
        {:ok, params} ->
          stop_prediction_tuples =
            Enum.map(params.stop_ids, fn stop_id ->
              {stop_id, stop_id, []}
            end)

          socket =
            assign(socket, :stop_prediction_tuples, stop_prediction_tuples)
            |> assign(:stop_prediction_map, %{})
            |> assign(:stop_ids, params.stop_ids)
            |> assign(:joined_stop_ids, nil)
            |> assign(:joined_stop_names, nil)
            |> assign(:add_stop_button_text, "Save Stop")
            |> assign(:params, params)
            |> assign(:valid, true)
            |> assign(:title, title)
            |> assign(:location, location)

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
    route_ids = Map.get(socket.assigns.params, :route_ids)
    limit = Map.get(socket.assigns.params, :limit)

    predictions = filter_predictions(predictions, route_ids, limit)

    map = Map.put(socket.assigns.stop_prediction_map, stop_id, predictions)

    stop_prediction_tuples =
      Enum.map(socket.assigns.stop_ids, fn stop_id ->
        predictions = Map.get(map, stop_id, [])

        formatted_predictions =
          Enum.map(predictions, fn prediction ->
            {prediction.route_display, String.capitalize(prediction.route_direction),
             KioskView.format_arrival(prediction), KioskView.format_predicted_time(prediction),
             prediction.trip_id}
          end)

        stop_name = KioskView.stop_name(stop_id, predictions)
        {stop_id, stop_name, formatted_predictions}
      end)

    socket =
      assign(socket, :stop_prediction_map, map)
      |> assign(:stop_prediction_tuples, stop_prediction_tuples)
      |> setup_add_button_assigns(stop_prediction_tuples)

    {:noreply, socket}
  end

  def handle_info(_message, socket) do
    {:noreply, socket}
  end

  def render(assigns) do
    if assigns.valid do
      Phoenix.View.render(KioskView, "page.html", assigns)
    else
      ~L"""
      <div>
        <p>Oops, looks like there was an error with the stops you asked for.</p>
        <%= Phoenix.HTML.Link.link "Let's try again", to: BusKioskWeb.Router.Helpers.live_path(BusKioskWeb.Endpoint, BusKioskWeb.HomeLive, %{}) %>
      </div>
      """
    end
  end

  defp setup_add_button_assigns(socket, stop_prediction_tuples) do
    all_stops_have_predictions =
      Enum.all?(stop_prediction_tuples, fn {_, _, predictions} ->
        if length(predictions) > 0 do
          true
        else
          false
        end
      end)

    joined_stop_names =
      Enum.map(stop_prediction_tuples, fn {_, name, _} -> name end)
      |> Enum.join(",")

    joined_stop_ids =
      Enum.map(stop_prediction_tuples, fn {stop_id, _, _} -> stop_id end)
      |> Enum.join(",")

    save_stop_button_text =
      if length(stop_prediction_tuples) > 1 do
        "Save Stop Group"
      else
        "Save Stop"
      end

    if all_stops_have_predictions do
      assign(socket, :joined_stop_names, joined_stop_names)
      |> assign(:joined_stop_ids, joined_stop_ids)
      |> assign(:save_stop_button_text, save_stop_button_text)
    else
      socket
    end
  end

  defp filter_predictions(predictions, nil, nil), do: predictions
  defp filter_predictions(predictions, nil, limit), do: Enum.take(predictions, limit)

  defp filter_predictions(predictions, route_ids, nil) do
    Enum.filter(predictions, fn prediction ->
      Enum.member?(route_ids, prediction.route)
    end)
  end

  defp filter_predictions(predictions, route_ids, limit) do
    Enum.filter(predictions, fn prediction ->
      Enum.member?(route_ids, prediction.route)
    end)
    |> Enum.take(limit)
  end
end
