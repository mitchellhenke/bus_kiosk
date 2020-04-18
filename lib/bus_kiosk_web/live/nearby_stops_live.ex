defmodule BusKioskWeb.NearbyStopsLive do
  use Phoenix.LiveView

  defmodule Params do
    defstruct [:latitude, :longitude, :heading]

    def change(params) do
      types = %{
        latitude: :float,
        longitude: :float,
        heading: :float
      }

      data = %Params{}

      Ecto.Changeset.cast({data, types}, params, [:latitude, :longitude, :heading])
      |> Ecto.Changeset.validate_required([])
    end
  end

  def mount(_params, _session, socket) do
    changeset = Params.change(%{})

    socket =
      assign(socket, :changeset, changeset)
      |> assign(:latitude, nil)
      |> assign(:longitude, nil)
      |> assign(:heading, nil)
      |> assign(:stops, [])

    {:ok, socket}
  end

  def handle_params(params, _uri, socket) do
    changeset = Params.change(params)
    socket = handle_changeset(socket, changeset)

    {:noreply, socket}
  end

  def handle_event("location", %{"error" => _er}, socket) do
    {:noreply, socket}
  end

  def handle_event("location", params, socket) do
    changeset = Params.change(params)

    socket = handle_changeset(socket, changeset)

    {:noreply, socket}
  end

  def render(assigns) do
    Phoenix.View.render(BusKioskWeb.NearbyStopsView, "page.html", assigns)
  end

  def get_stops(nil, _longitude), do: []
  def get_stops(_latitude, nil), do: []

  def get_stops(latitude, longitude) do
    point = %Geo.Point{
      coordinates: {longitude, latitude},
      properties: %{},
      srid: 4326
    }

    BusKiosk.Gtfs.Stop.get_nearest(point)
  end

  defp handle_changeset(socket, changeset) do
    case Ecto.Changeset.apply_action(changeset, :insert) do
      {:ok, params} ->
        socket =
          case params do
            %{latitude: lat, longitude: lon} when is_float(lat) and is_float(lon) ->
              stops = get_stops(lat, lon)

              assign(socket, :latitude, lat)
              |> assign(:longitude, lon)
              |> assign(:stops, stops)

            _ ->
              socket
          end

        socket =
          if Map.has_key?(params, :heading) && not is_nil(params.heading) do
            assign(socket, :heading, params.heading)
          else
            socket
          end

        stops =
          if not is_nil(socket.assigns.heading) do
            Enum.map(socket.assigns.stops, fn stop ->
              Map.put(
                stop,
                :adjusted_azimuth,
                rem(trunc(stop.azimuth) - trunc(socket.assigns.heading) + 360, 360)
              )
            end)
          else
            Enum.map(socket.assigns.stops, fn stop ->
              Map.put(stop, :adjusted_azimuth, nil)
            end)
          end

        assign(socket, :changeset, changeset)
        |> assign(:params, params)
        |> assign(:stops, stops)

      {:error, error_changeset} ->
        assign(socket, :changeset, error_changeset)
        |> assign(:params, nil)
        |> assign(:stops, [])
    end
  end
end
