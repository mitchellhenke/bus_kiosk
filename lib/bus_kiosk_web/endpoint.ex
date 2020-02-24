defmodule BusKioskWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :bus_kiosk

  # The session will be stored in the cookie and signed,
  # this means its contents can be read but not tampered with.
  # Set :encryption_salt if you would also like to encrypt it.
  @session_options [
    store: :cookie,
    key: "_bus_kiosk_key",
    signing_salt: "XF3jHs9n"
  ]

  socket "/live", Phoenix.LiveView.Socket,
    websocket: [compress: true, connect_info: [session: @session_options]]

  # Serve at "/" the static files from "priv/static" directory.
  #
  # You should set gzip to true if you are running phx.digest
  # when deploying your static files in production.
  plug Plug.Static,
    at: "/",
    from: :bus_kiosk,
    gzip: true,
    only:
      ~w(css fonts images js favicon.ico site.webmanifest apple-touch-icon.png favicon-16x16.png favicon-32x32.png android-chrome-192x192.png android-chrome-512x512.png robots.txt)

  # Code reloading can be explicitly enabled under the
  # :code_reloader configuration of your endpoint.
  if code_reloading? do
    socket "/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket
    plug Phoenix.LiveReloader
    plug Phoenix.CodeReloader
  end

  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug Plug.MethodOverride
  plug Plug.Head
  plug Plug.Session, @session_options
  plug BusKioskWeb.Router
end
