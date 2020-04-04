defmodule BusKioskWeb.Router do
  use BusKioskWeb, :router
  import Phoenix.LiveView.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :fetch_live_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :live_layout do
    plug :put_root_layout, {BusKioskWeb.LayoutView, :live}
  end

  scope "/", BusKioskWeb do
    pipe_through :browser

    scope "/" do
      pipe_through :live_layout
      live "/", HomeLive
      live "/nearby_stops", NearbyStopsLive
      live "/live", KioskLive
    end

    get "/saved_stops", SavedStopController, :index
  end

  # Other scopes may use custom stacks.
  # scope "/api", BusKioskWeb do
  #   pipe_through :api
  # end
end
