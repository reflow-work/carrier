defmodule CarrierWeb.App.ReportLive.Index do
  use CarrierWeb, :live_view
  alias Carrier.Reports
  alias Carrier.Core.TimeHelper

  on_mount(CarrierWeb.OnboardingHook)
  on_mount(CarrierWeb.IntegrationHook)

  @impl true
  def mount(params, session, socket) do
    socket =
      socket
      |> assign(:reports, [])

    socket =
      case connected?(socket) do
        true ->
          socket = socket |> load_reports()

          case length(socket.assigns.reports) < 1 do
            true -> socket |> push_navigate(to: Routes.report_new_path(socket, :new))
            _ -> socket
          end

        false ->
          socket
      end

    socket =
      case params do
        %{"redirected" => "true"} ->
          push_event(socket, "smartlook_identify", %{
            "orgId" => session["org_id"],
            "userId" => session["user_id"]
          })

        _ ->
          socket
      end

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    socket =
      case socket.assigns.live_action do
        :index ->
          socket

        :delete ->
          report_id = params["id"] |> String.to_integer()

          socket
          |> assign(:report_id, report_id)
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event("delete_report", _params, socket) do
    socket =
      socket
      |> delete_report(socket.assigns.report_id)

    {:noreply, socket}
  end

  defp load_reports(socket) do
    case Reports.list_reports() do
      {:ok, reports} ->
        socket |> assign(:reports, reports)
    end
  end

  defp delete_report(socket, report_id) do
    case Reports.delete_report(report_id) do
      {:ok, _deleted_report} ->
        socket
        |> update(:reports, fn reports -> reports |> Enum.reject(&(&1.id == report_id)) end)
        |> push_patch(to: Routes.report_index_path(socket, :index))

      {:error, reason} ->
        socket
        |> put_flash_for(:error, inspect(reason), timeout: :timer.seconds(3))
    end
  end

  defp format_trigger_time(trigger_time, timezone) do
    TimeHelper.from_utc_time(trigger_time, timezone)
    |> Timex.format!("매일 {_h24}시")
  end
end
