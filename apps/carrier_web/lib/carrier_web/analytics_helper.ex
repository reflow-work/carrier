defmodule CarrierWeb.AnalyticsHelper do
  import Phoenix.LiveView, only: [push_event: 3]

  def log_event(socket, name, properties \\ %{}) do
    socket
    |> push_event("log-event", %{name: name, properties: properties})
  end
end
