defmodule BusKioskWeb.StopPredictionComponent do
  use Phoenix.LiveComponent

  def render(assigns) do
    ~L"""
      <tr>
        <td><strong><%= @route %></strong></td>
        <td><%= @direction %></td>
        <td><%= @arrival %></td>
        <td><%= @predicted_time %></td>
        <%# <td><%= format_only_time(prediction.timestamp) %1></td> %>
      </tr>
    """
  end
end
