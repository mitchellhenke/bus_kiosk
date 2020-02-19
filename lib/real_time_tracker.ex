defmodule BusKiosk.RealTimeTracker do
  @behaviour Phoenix.Tracker
  alias Phoenix.PubSub

  def start_link(opts) do
    opts = Keyword.merge([name: __MODULE__], opts)
    Phoenix.Tracker.start_link(__MODULE__, opts, opts)
  end

  def init(opts) do
    server = Keyword.fetch!(opts, :pubsub_server)
    {:ok, %{pubsub_server: server, node_name: PubSub.node_name(server)}}
  end

  def handle_diff(diff, state) do
    Enum.each(diff, fn {topic, {joins, leaves}} ->
      broadcast_joins(joins, topic, state)
      broadcast_leaves(leaves, topic, state)
    end)

    {:ok, state}
  end

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      type: :worker,
      restart: :permanent,
      shutdownw: 500
    }
  end

  defp broadcast_joins([], _topic, _state), do: nil

  defp broadcast_joins(joins, "stops:" <> stop_id, state) do
    Enum.each(joins, fn {_key, _meta} ->
      PubSub.direct_broadcast!(
        state.node_name,
        state.pubsub_server,
        "realtime_diff",
        {:joined, stop_id}
      )
    end)
  end

  defp broadcast_joins(_joins, _topic, _state), do: nil

  defp broadcast_leaves([], _topic, _state), do: nil

  defp broadcast_leaves(leaves, "stops:" <> stop_id, state) do
    Enum.each(leaves, fn {_key, _meta} ->
      PubSub.direct_broadcast!(
        state.node_name,
        state.pubsub_server,
        "realtime_diff",
        {:left, stop_id}
      )
    end)
  end

  defp broadcast_leaves(_leaves, _topic, _state), do: nil
end
