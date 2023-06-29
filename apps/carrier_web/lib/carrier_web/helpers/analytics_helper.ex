defmodule CarrierWeb.AnalyticsHelper do
  import Phoenix.LiveView, only: [push_event: 3]
  alias Carrier.Core.Nillable
  alias Phoenix.LiveView.JS

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

  def js_log_event(js \\ %JS{}, name)

  def js_log_event(%JS{} = js, name), do: js_log_event(js, name, %{})
  def js_log_event(name, properties), do: js_log_event(%JS{}, name, properties)

  def js_log_event(%JS{} = js, name, properties) do
    js
    |> JS.dispatch("phx:analytics-log-event", detail: %{name: name, properties: properties})
  end
end
