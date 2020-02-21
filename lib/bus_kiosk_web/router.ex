defmodule BusKioskWeb.Router do
  use BusKioskWeb, :router
  import Phoenix.LiveView.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug Phoenix.LiveView.Flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", BusKioskWeb do
    pipe_through :browser

    live "/", NearbyStopsLive
    live "/live", KioskLive
  end

  # Other scopes may use custom stacks.
  # scope "/api", BusKioskWeb do
  #   pipe_through :api
  # end
end
