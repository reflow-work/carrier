defmodule CarrierWeb.App.DataTargetLive.New do
  use CarrierWeb, :live_view
  alias CarrierWeb.Components.Slack
  alias CarrierWeb.Helpers.SlackHelper

  on_mount(CarrierWeb.NoDataTargetHook)

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(params, _uri, %{assigns: %{live_action: :new}} = socket) do
    socket =
      socket
      |> assign(:redirect_uri, SlackHelper.get_redirect_uri(nil, params["popup"]))

    {:noreply, socket}
  end

  @impl true
  def handle_params(
        %{"data_target_id" => data_target_id_str} = params,
        _uri,
        %{assigns: %{live_action: :edit}} = socket
      ) do
    socket =
      socket
      |> assign(:redirect_uri, SlackHelper.get_redirect_uri(data_target_id_str, params["popup"]))

    {:noreply, socket}
  end
end
