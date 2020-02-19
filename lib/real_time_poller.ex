defmodule BusKiosk.RealTimePoller do
  use GenServer
  alias Phoenix.PubSub
  require Logger

  @default_opts %{poll_interval_milliseconds: 60_000}
  @real_time_module Application.compile_env!(:bus_kiosk, :real_time_module)

  def start_link(opts \\ %{}) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def subscribe(stop_ids) do
    Enum.each(stop_ids, fn stop_id ->
      {:ok, _} =
        Phoenix.Tracker.track(
          BusKiosk.RealTimeTracker,
          self(),
          "stops:#{stop_id}",
          inspect(:erlang.make_ref()),
          %{}
        )

      :ok = PubSub.subscribe(BusKiosk.PubSub, "stops:#{stop_id}")
    end)

    GenServer.cast(__MODULE__, {:refresh_predictions, stop_ids})
  end

  def init(opts) do
    opts =
      Map.merge(@default_opts, opts)
      |> Map.put(:stop_id_set, MapSet.new())

    :ok = PubSub.subscribe(BusKiosk.PubSub, "realtime_diff")
    Process.send_after(self(), :refresh_predictions, opts.poll_interval_milliseconds)
    {:ok, opts}
  end

  def handle_cast({:refresh_predictions, stop_ids}, state) do
    refresh_predictions(stop_ids)

    {:noreply, state}
  end

  def handle_info(:refresh_predictions, state) do
    Enum.to_list(state.stop_id_set)
    |> refresh_predictions()

    Process.send_after(self(), :refresh_predictions, state.poll_interval_milliseconds)
    {:noreply, state}
  end

  def handle_info({:joined, stop_id}, state) do
    {:noreply,
     %{
       state
       | stop_id_set: MapSet.put(state.stop_id_set, stop_id)
     }}
  end

  def handle_info({:left, stop_id}, state) do
    presences = Phoenix.Tracker.list(BusKiosk.RealTimeTracker, "stops:#{stop_id}")

    set =
      if presences == [] do
        MapSet.delete(state.stop_id_set, stop_id)
      else
        state.stop_id_set
      end

    {:noreply,
     %{
       state
       | stop_id_set: set
     }}
  end

  def handle_info(_msg, state) do
    {:noreply, state}
  end

  def refresh_predictions([]), do: nil
  # Can only request up to 10 stop_ids per request
  def refresh_predictions(stop_ids) do
    Enum.chunk_every(stop_ids, 10)
    |> Enum.each(fn stop_ids_10 ->
      case @real_time_module.get_predictions(stop_ids_10) do
        {:ok, predictions} ->
          Enum.group_by(predictions, & &1.stop_id)
          |> Enum.each(fn {stop_id, predictions} ->
            sorted_predictions =
              Enum.sort(
                predictions,
                &(NaiveDateTime.compare(&1.predicted_time, &2.predicted_time) == :lt)
              )

            PubSub.broadcast(
              BusKiosk.PubSub,
              "stops:#{stop_id}",
              {:bus_predictions, stop_id, sorted_predictions}
            )
          end)

        e ->
          Logger.error("Error refreshing predictions: #{inspect(e)}")
      end
    end)
  end
end
