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
      Enum.each(joins, fn {key, meta} ->
        case String.split(topic, ":") do
          ["stops", stop_id] ->
            PubSub.direct_broadcast!(
              state.node_name,
              state.pubsub_server,
              "realtime_diff",
              {:joined, stop_id}
            )

          _ ->
            nil
        end
      end)

      Enum.each(leaves, fn {key, meta} ->
        case String.split(topic, ":") do
          ["stops", stop_id] ->
            PubSub.direct_broadcast!(
              state.node_name,
              state.pubsub_server,
              "realtime_diff",
              {:left, stop_id}
            )

          _ ->
            nil
        end
      end)
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
end
