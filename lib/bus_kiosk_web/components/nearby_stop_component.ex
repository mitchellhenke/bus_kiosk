defmodule BusKioskWeb.NearbyStopComponent do
  use Phoenix.LiveComponent
  alias BusKioskWeb.Router.Helpers, as: Routes
  import BusKioskWeb.NearbyStopsView

  def render(assigns) do
    ~L"""
      <div>
        <%= live_redirect to: Routes.live_path(@socket, BusKioskWeb.KioskLive, stop_ids: @stop_id) do %>
          <span><%= "#{@stop_name} (#{@distance} ft" %></span><%= azimuth_emoji(@adjusted_azimuth) %><span>)</span>
        <% end %>
        <div><%= stop_route_ids(@route_ids) %></div>
      </div>
    """
  end
end
