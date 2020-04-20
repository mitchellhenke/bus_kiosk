defmodule BusKioskWeb.NearbyStopComponent do
  use Phoenix.LiveComponent
  alias BusKioskWeb.Router.Helpers, as: Routes
  import BusKioskWeb.NearbyStopsView

  def render(assigns) do
    ~L"""
    <div>
      <a href="<%= Routes.live_path(@socket, BusKioskWeb.KioskLive, stop_ids: @stop_id) %>">
      <div>
        <%= "#{@stop_name}" %>
        <%= if @adjusted_azimuth do %>
          <%= "(#{@distance} ft " %>

          <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 330 330" height="10" width="10"><path fill="#9b4dca" d="M325.606 229.393l-150.004-150C172.8 76.58 168.974 75 164.996 75a15 15 0 0 0-10.607 4.394l-149.996 150c-5.858 5.858-5.858 15.355 0 21.213s15.355 5.858 21.213 0l139.4-139.393 139.397 139.393c2.93 2.93 6.768 4.393 10.607 4.393a14.95 14.95 0 0 0 10.607-4.394c5.857-5.858 5.857-15.355-.001-21.213z"
          transform="rotate(<%= @adjusted_azimuth %> 165 165)"/>
          </svg>)
        <% else %>
          <%= "(#{@distance} ft)" %>
        <% end %>
      </div>
    </a>
    <div><%= stop_route_ids(@route_ids) %></div>
    </div>
    """
  end
end
