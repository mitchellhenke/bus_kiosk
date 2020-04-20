defmodule BusKiosk.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    # List all child processes to be supervised
    children = [
      # Start the Ecto repository
      BusKiosk.Repo,
      # Start the endpoint when the application starts
      {Phoenix.PubSub, [name: BusKiosk.PubSub, adapter: Phoenix.PubSub.PG2]},
      BusKioskWeb.Endpoint,
      # Starts a worker by calling: BusKiosk.Worker.start_link(arg)
      {BusKiosk.RealTimeTracker, [name: BusKiosk.RealTimeTracker, pubsub_server: BusKiosk.PubSub]}
    ]

    poller_enabled = Application.get_env(:bus_kiosk, :real_time_polling_enabled)

    children =
      if poller_enabled do
        children ++ [{BusKiosk.RealTimePoller, %{}}]
      else
        children
      end

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: BusKiosk.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    BusKioskWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
