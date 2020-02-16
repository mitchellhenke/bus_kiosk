defmodule BusKioskWeb.KioskLive do
  use Phoenix.LiveView
  alias BusKiosk.RealTime

  defmodule Params do
    defstruct [:stop_ids]

    def change(params) do
      types = %{
        stop_ids: {:array, :integer}
      }

      data = %Params{}

      {data, types}
      |> Ecto.Changeset.cast(params, [:stop_ids])
      |> Ecto.Changeset.validate_required([:stop_ids])
      |> Ecto.Changeset.validate_length(:stop_ids, min: 1)
    end
  end

  def mount(params, _session, socket) do
    title = Map.get(params, "title", "Bus Stop")
    location = Map.get(params, "location")

    params =
      Map.update(params, "stop_ids", nil, fn stop_ids ->
        String.split(stop_ids, ",")
      end)

    changeset = Params.change(params)

    socket =
      case Ecto.Changeset.apply_action(changeset, :insert) do
        {:ok, params} ->
          Process.send_after(self(), :refresh_predictions, 0)

          assign(socket, :stop_ids, params.stop_ids)
          |> assign(:valid, true)
          |> assign(:title, title)
          |> assign(:location, location)
          |> assign(:predictions, [])

        {:error, _cs} ->
          assign(socket, :valid, false)
      end

    {:ok, socket}
  end

  def handle_info(:refresh_predictions, socket) do
    case RealTime.get_predictions(socket.assigns.stop_ids) do
      {:ok, predictions} ->
        Process.send_after(self(), :refresh_predictions, 60_000)
        socket = assign(socket, :predictions, predictions)
        {:noreply, socket}

      _ ->
        {:noreply, socket}
    end
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
end
