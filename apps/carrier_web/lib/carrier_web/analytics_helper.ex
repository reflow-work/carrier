defmodule CarrierWeb.AnalyticsHelper do
  import Phoenix.LiveView, only: [push_event: 3]
  alias Carrier.Core.Nillable

  def init_analytics(socket) do
    socket
    |> push_event("analytics-init", %{
      user_id: socket.assigns[:user_id] |> Nillable.map(&(&1 |> to_string()))
    })
  end

  def log_event(socket, name, properties \\ %{}) do
    socket
    |> push_event("analytics-log-event", %{name: name, properties: properties})
  end
end
