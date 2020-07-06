defmodule BusKioskWeb.StopPredictionsComponent do
  use Phoenix.LiveComponent

  def render(assigns) do
    ~L"""
      <div class="prediction-item">
        <h1 class="route"><%= @stop_name %></h1>
        <table>
          <thead>
            <tr>
              <th>Route</th>
              <th>Direction</th>
              <th>Arrival</th>
              <th>Est. Time</th>
            </tr>
          </thead>
          <tbody>
            <%= for {route, direction, arrival, predicted_time, trip_id} <- @predictions do  %>
              <%= live_component(@socket, BusKioskWeb.StopPredictionComponent, id: trip_id, route: route,
              direction: direction, arrival: arrival, predicted_time: predicted_time) %>
            <% end %>
          </tbody>
        </table>
      </div>
    """
  end
end
