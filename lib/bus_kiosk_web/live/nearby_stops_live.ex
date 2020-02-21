defmodule BusKioskWeb.NearbyStopsLive do
  use Phoenix.LiveView

  defmodule Params do
    defstruct [:stop_ids]

    def change(params) do
      types = %{
        stop_ids: {:array, :integer},
        stop_ids_text: :string
      }

      data = %Params{}

      changeset =
        Ecto.Changeset.cast({data, types}, params, [:stop_ids_text])
        |> Ecto.Changeset.validate_required([:stop_ids_text])

      stop_ids =
        Ecto.Changeset.get_change(changeset, :stop_ids_text, "")
        |> String.trim_trailing(",")
        |> String.replace(", ", "")
        |> String.split(",")
        |> Enum.uniq()

      Ecto.Changeset.cast(changeset, %{stop_ids: stop_ids}, [:stop_ids])
      |> Ecto.Changeset.validate_required([:stop_ids])
      |> Ecto.Changeset.validate_length(:stop_ids, min: 1, max: 4)
    end
  end

  def mount(_params, _session, socket) do
    changeset = Params.change(%{})
    socket = assign(socket, :changeset, changeset)

    {:ok, socket}
  end

  def handle_event("change", %{"params" => params}, socket) do
    socket = handle_params(socket, params)
    {:noreply, socket}
  end

  def handle_event("submit", _params, socket) do
    {:stop,
     redirect(socket,
       to:
         BusKioskWeb.Router.Helpers.live_path(socket, BusKioskWeb.KioskLive, %{
           stop_ids: socket.assigns.params.stop_ids_text
         })
     )}
  end

  def render(assigns) do
    Phoenix.View.render(BusKioskWeb.NearbyStopsView, "page.html", assigns)
  end

  defp handle_params(socket, params) do
    changeset = Params.change(params)

    case Ecto.Changeset.apply_action(changeset, :insert) do
      {:ok, params} ->
        assign(socket, :changeset, changeset)
        |> assign(:params, params)

      {:error, error_changeset} ->
        assign(socket, :changeset, error_changeset)
    end
  end
end
