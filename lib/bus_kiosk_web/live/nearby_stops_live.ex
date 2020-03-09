defmodule BusKioskWeb.NearbyStopsLive do
  use Phoenix.LiveView

  defmodule Params do
    defstruct [:latitude, :longitude]

    def change(params) do
      types = %{
        latitude: :float,
        longitude: :float,
      }

      data = %Params{}

      Ecto.Changeset.cast({data, types}, params, [:latitude, :longitude])
      |> Ecto.Changeset.validate_required([:latitude, :longitude])
    end
  end

  def mount(_params, _session, socket) do
    changeset = Params.change(%{})
    socket = assign(socket, :changeset, changeset)
             |> assign(:latitude, nil)
             |> assign(:longitude, nil)
             |> assign(:stops, [])


    {:ok, socket}
  end

  def handle_params(params, _uri, socket) do
    changeset = Params.change(params)
    socket = handle_changeset(socket, changeset)

    {:noreply, socket}
  end

  def handle_event("location", %{"latitude" => lat, "longitude" => lon}, socket) do
    changeset = Params.change(%{latitude: lat, longitude: lon})

    socket = assign(socket, :latitude, lat)
             |> assign(:longitude, lon)
             |> handle_changeset(changeset)

    {:noreply, socket}
  end

  def handle_event("location", error, socket) do
    IO.inspect(error)

    {:noreply, socket}
  end

  def render(assigns) do
    Phoenix.View.render(BusKioskWeb.NearbyStopsView, "page.html", assigns)
  end

  def get_stops(params) do
    IO.inspect(params)
    point = %Geo.Point{coordinates: {params.longitude, params.latitude}, properties: %{}, srid: 4326}

    BusKiosk.Gtfs.Stop.get_nearest(point)
  end

  defp handle_changeset(socket, changeset) do
    case Ecto.Changeset.apply_action(changeset, :insert) do
      {:ok, params} ->
        socket = assign(socket, :changeset, changeset)
                 |> assign(:params, params)

        stops = get_stops(params)

        assign(socket, :stops, stops)

      {:error, error_changeset} ->
        assign(socket, :changeset, error_changeset)
        |> assign(:params, nil)
        |> assign(:stops, [])
    end
  end
end
