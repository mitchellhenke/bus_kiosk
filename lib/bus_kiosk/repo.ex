defmodule BusKiosk.Repo do
  use Ecto.Repo,
    otp_app: :bus_kiosk,
    adapter: Ecto.Adapters.Postgres
end
