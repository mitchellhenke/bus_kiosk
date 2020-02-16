defmodule BusKiosk.RealTimePoller do
  use GenServer
  alias Phoenix.PubSub
  require Logger

  @default_opts %{poll_interval_milliseconds: 60_000}

  def start_link(opts \\ %{}) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def subscribe(stop_ids) do
    Enum.each(stop_ids, fn stop_id ->
      PubSub.subscribe(BusKiosk.PubSub, "stops:#{stop_id}")
    end)

    GenServer.call(__MODULE__, {:subscribe, stop_ids})
  end

  def init(opts) do
    opts =
      Map.merge(@default_opts, opts)
      |> Map.put(:stop_id_set, MapSet.new())
      |> Map.put(:stop_id_pid_map, %{})
      |> Map.put(:pid_stop_id_map, %{})

    {:ok, opts}
  end

  # live view will subscribe to stops:34, stops:55, stops:59 (through Poller)

  def handle_call({:subscribe, stop_ids}, {pid, _ref}, state) do
    _ref = Process.monitor(pid)
    state = add_pid_stop_ids(pid, stop_ids, state)
    Process.send_after(self(), :refresh_predictions, 0)

    {:reply, :ok, state}
  end

  def handle_info({:DOWN, _ref, :process, pid, _reason}, state) do
    state = cleanup_stop_ids_after_down_pid(pid, state)
    {:noreply, state}
  end

  def handle_info(:refresh_predictions, state) do
    Enum.to_list(state.stop_id_set)
    |> refresh_predictions()

    Process.send_after(self(), :refresh_predictions, 60_000)
    {:noreply, state}
  end

  def handle_info(_msg, state) do
    {:noreply, state}
  end

  defp cleanup_stop_ids_after_down_pid(pid, state) do
    {stop_ids, pid_stop_id_map} = Map.pop(state.pid_stop_id_map, pid)

    {stop_id_pid_map, stop_id_set} =
      Enum.reduce(stop_ids, {state.stop_id_pid_map, state.stop_id_set}, fn stop_id, {map, set} ->
        pids = Map.fetch!(map, stop_id)
        updated_pids = MapSet.delete(pids, pid)
        map = Map.put(map, stop_id, updated_pids)

        # if last pid removed for stop_id, remove stop from poll set
        if MapSet.size(updated_pids) == 0 do
          {map, MapSet.delete(set, stop_id)}
        else
          {map, set}
        end
      end)

    %{
      state
      | stop_id_set: stop_id_set,
        pid_stop_id_map: pid_stop_id_map,
        stop_id_pid_map: stop_id_pid_map
    }
  end

  defp add_pid_stop_ids(pid, stop_ids, state) do
    stop_id_set = MapSet.union(state.stop_id_set, MapSet.new(stop_ids))
    pid_stop_id_map = Map.put(state.pid_stop_id_map, pid, stop_ids)

    stop_id_pid_map =
      Enum.reduce(stop_ids, state.stop_id_pid_map, fn stop_id, map ->
        Map.update(map, stop_id, MapSet.new([pid]), fn current_set ->
          MapSet.put(current_set, pid)
        end)
      end)

    %{
      state
      | stop_id_set: stop_id_set,
        pid_stop_id_map: pid_stop_id_map,
        stop_id_pid_map: stop_id_pid_map
    }
  end

  def refresh_predictions([]), do: nil
  # Can only request up to 10 stop_ids per request
  def refresh_predictions(stop_ids) do
    Enum.chunk_every(stop_ids, 10)
    |> Enum.each(fn stop_ids_10 ->
      case BusKiosk.RealTime.get_predictions(stop_ids_10) do
        {:ok, predictions} ->
          Enum.group_by(predictions, & &1.stop_id)
          |> Enum.each(fn {stop_id, predictions} ->
            PubSub.broadcast(
              BusKiosk.PubSub,
              "stops:#{stop_id}",
              {:bus_predictions, stop_id, predictions}
            )
          end)

        e ->
          Logger.error("Error refreshing predictions: #{inspect(e)}")
      end
    end)
  end
end
