defmodule BusKioskWeb.HomeLive do
  use Phoenix.LiveView

  defmodule Params do
    defstruct [:stop_ids]

    def change(params) do
      types = %{
        stop_ids: :string,
        stop_ids_integers: {:array, :integer}
      }

      data = %Params{}

      changeset =
        Ecto.Changeset.cast({data, types}, params, [:stop_ids])
        |> Ecto.Changeset.validate_required([:stop_ids])

      stop_ids_integers =
        Ecto.Changeset.get_change(changeset, :stop_ids, "")
        |> String.trim_trailing(",")
        |> String.replace(", ", "")
        |> String.split(",")
        |> Enum.uniq()

      Ecto.Changeset.cast(changeset, %{stop_ids_integers: stop_ids_integers}, [:stop_ids_integers])
      |> Ecto.Changeset.validate_required([:stop_ids_integers])
      |> Ecto.Changeset.validate_length(:stop_ids_integers, min: 1, max: 4)
    end
  end

  def mount(_params, _session, socket) do
    changeset = Params.change(%{})
    socket = assign(socket, :changeset, changeset)

    {:ok, socket}
  end

  def handle_params(params, _uri, socket) do
    changeset = Params.change(params)
    socket = handle_changeset(socket, changeset)

    {:noreply, socket}
  end

  def handle_event("change", %{"params" => params}, socket) do
    changeset = Params.change(params)
    socket = handle_changeset(socket, changeset)

    socket =
      case Map.fetch(socket.assigns, :params) do
        {:ok, %{stop_ids_integers: _, stop_ids: text}} ->
          path =
            BusKioskWeb.Router.Helpers.live_path(socket, BusKioskWeb.HomeLive, %{
              stop_ids: text
            })

          push_patch(socket, to: path)

        _ ->
          socket
      end

    {:noreply, socket}
  end

  def handle_event("submit", _params, socket) do
    {:noreply,
     redirect(socket,
       to:
         BusKioskWeb.Router.Helpers.live_path(socket, BusKioskWeb.KioskLive, %{
           stop_ids: socket.assigns.params.stop_ids
         })
     )}
  end

  def render(assigns) do
    Phoenix.View.render(BusKioskWeb.HomeView, "page.html", assigns)
  end

  defp handle_changeset(socket, changeset) do
    case Ecto.Changeset.apply_action(changeset, :insert) do
      {:ok, params} ->
        assign(socket, :changeset, changeset)
        |> assign(:params, params)

      {:error, error_changeset} ->
        assign(socket, :changeset, error_changeset)
        |> assign(:params, nil)
    end
  end
end
