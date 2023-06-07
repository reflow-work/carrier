defmodule CarrierWeb.App.ReportLive.New2 do
  use CarrierWeb, :live_view
  use Carrier.{Integrations, Data, Reports}
  alias __MODULE__.Components
  alias __MODULE__.ReportParams
  alias Carrier.Core.{Nillable, Async, TimeHelper}
  alias Doumi.Phoenix.Params

  on_mount(CarrierWeb.DataTargetHook)
  on_mount(CarrierWeb.DataSourceHook)

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:action, nil)
      |> assign(:title, nil)
      |> assign(:report, nil)
      |> assign(:data_source_info, nil)
      |> assign(:data_target_info, nil)
      |> assign(:selected_data_source, nil)
      |> assign(:data_source_info_form, nil)
      |> assign(:data_target_info_form, nil)
      |> assign(:report_form, nil)
      |> assign(:valid?, false)

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _uri, %{assigns: %{live_action: :new}} = socket) do
    data_source_id =
      params["data_source_id"] |> Nillable.map(&Obfuscatable.deobfuscate!(&1, DataSource))

    report_form = ReportParams.to_form(%{}, validate: false)

    socket =
      socket
      |> assign(:action, :new)
      |> assign(:title, "레포트 생성하기")
      |> Nillable.run(data_source_id, fn socket ->
        socket
        |> assign(
          :selected_data_source,
          socket.assigns.data_sources |> Enum.find(&(&1.id == data_source_id))
        )
      end)
      |> assign(:report_form, report_form)

    {:noreply, socket}
  end

  @impl true
  def handle_params(params, _uri, %{assigns: %{live_action: :edit}} = socket) do
    report_id = params["report_id"] |> Nillable.map(&Obfuscatable.deobfuscate!(&1, Report))

    socket = socket |> load_report(report_id)

    report = socket.assigns.report

    report_form =
      ReportParams.to_form(
        report
        |> Map.from_struct()
        |> Map.update!(:trigger_time, &(&1 |> TimeHelper.from_utc_time(report.timezone))),
        validate: false
      )

    data_source_info = report.data_source_info |> Map.from_struct()
    data_target_info = report.data_target_info |> Map.from_struct()

    selected_data_source =
      socket.assigns.data_sources |> Enum.find(&(&1.id == data_source_info.data_source_id))

    socket =
      socket
      |> assign(:action, :edit)
      |> assign(:title, "레포트 수정하기")
      |> assign(:selected_data_source, selected_data_source)
      |> assign(:data_source_info, data_source_info)
      |> assign(:data_target_info, data_target_info)
      |> assign(:report_form, report_form)

    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <section class="page-container">
      <.page_header icon="📊" title={@title} />
      <Components.data_source_selector
        data_sources={@data_sources}
        selected_data_source={@selected_data_source}
        onselect="select_data_source"
      />
      <div :if={@selected_data_source}>
        <Components.data_transformer
          data_source={@selected_data_source}
          data_source_info={@data_source_info}
        />
        <Components.report_configurer report_form={@report_form} valid?={@valid?} />
        <Components.data_target_configurer
          data_target={@data_target}
          data_target_info={@data_target_info}
        />
        <div class="mt-8 space-x-4">
          <.button type="button" style={:outline} disabled={!@valid?} phx-click="send_test_report">
            테스트 발송
          </.button>
          <.button type="submit" disabled={!@valid?} phx-disable-with="생성 중">
            리포트 저장
          </.button>
        </div>
      </div>
    </section>
    """
  end

  ### Data Source Selector ###

  @impl true
  def handle_event("select_data_source", %{"id" => data_source_id_str}, socket) do
    data_source_id = data_source_id_str |> String.to_integer()
    data_source = socket.assigns.data_sources |> Enum.find(&(&1.id == data_source_id))

    # TODO : remove it
    socket =
      case data_source.source do
        :tableau ->
          socket
          |> assign(:selected_data_source, data_source)
          |> push_patch(to: ~p"/app/reports/new2?data_source_id=#{data_source}", replace: true)

        _ ->
          socket
          |> push_navigate(to: ~p"/app/reports/new?data_source_id=#{data_source}")
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event("validate_report", %{"report" => report_input}, socket) do
    socket =
      socket
      |> update_report_form(report_input)
      |> update_valid()

    {:noreply, socket}
  end

  @impl true
  def handle_event("create_report", %{"report" => _report_input}, socket) do
    report = socket.assigns.report_form |> Params.to_map()

    report =
      report
      |> Map.update!(
        :trigger_time,
        &(&1 |> TimeHelper.to_utc_time(report.timezone))
      )

    data_source_info = socket.assigns.data_source_info_form |> Params.to_map()
    data_target_info = socket.assigns.data_target_info_form |> Params.to_map()

    params =
      report
      |> Map.merge(%{
        data_source_info: data_source_info,
        data_target_info: data_target_info
      })

    socket =
      socket.assigns.action
      |> case do
        :new -> Reports.create_report(params)
        :edit -> Reports.update_report(socket.assigns.report.id, params)
      end
      |> case do
        {:ok, _report} ->
          socket
          |> put_flash_for(:info, "\"#{report.name}\" 레포트가 저장되었습니다.", timeout: :timer.seconds(3))
          |> push_navigate(to: ~p"/app/reports")

        {:error, error} ->
          Logger.error(inspect(error))

          socket |> put_flash_for(:error, "레포트 저장에 실패하였습니다.", timeout: :timer.seconds(3))
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event("send_test_report", _params, socket) do
    report = socket.assigns.report_form |> Params.to_map()
    data_source_info = socket.assigns.data_source_info_form |> Params.to_map()
    data_target_info = socket.assigns.data_target_info_form |> Params.to_map()

    Async.run(fn ->
      with {:ok, threads} <- Data.prepare_threads(data_source_info),
           :ok <- Data.send_messages(report, threads, data_target_info) do
        :ok
      else
        {:error, error} ->
          Logger.error("Failed to send test report: #{inspect(error)}")

          {:error, error}
      end
    end)

    socket =
      socket
      |> log_event("send_test_report", %{
        page_name: "report_new"
      })
      |> put_flash_for(:info, "선택한 쿼리 결과에 대한 슬랙 메시지가 발송되었습니다! 😊", timeout: :timer.seconds(3))

    {:noreply, socket}
  end

  @impl true
  def handle_info({:update, {:data_source_info_form, data_source_info_form}}, socket) do
    socket =
      socket
      |> assign(:data_source_info_form, data_source_info_form)
      |> update_valid()

    {:noreply, socket}
  end

  @impl true
  def handle_info({:update, {:data_target_info_form, data_target_info_form}}, socket) do
    socket =
      socket
      |> assign(:data_target_info_form, data_target_info_form)
      |> update_valid()

    {:noreply, socket}
  end

  @impl true
  def handle_info(message, socket) do
    case handle_async_assigns(message, socket) do
      {:ok, socket} ->
        {:noreply, socket}

      _ ->
        {:noreply, socket}
    end
  end

  defp load_report(socket, report_id) do
    case Reports.fetch_report(report_id) do
      {:ok, report} ->
        socket |> assign(:report, report)

      {:error, reason} ->
        socket
        |> put_flash_for(:error, "레포트를 불러오는데 실패하였습니다. (#{inspect(reason)})",
          timeout: :timer.seconds(3)
        )
        |> push_navigate(to: ~p"/app/reports")
    end
  end

  defp update_report_form(socket, report_input) do
    report_input =
      %{
        "org_id" => socket.assigns.org.org_id,
        "user_id" => socket.assigns.user.id,
        "timezone" => socket.assigns.timezone
      }
      |> Map.merge(report_input)

    report_form = ReportParams.to_form(report_input)

    socket
    |> assign(:report_form, report_form)
  end

  defp update_valid(socket) do
    valid? =
      [
        socket.assigns.data_source_info_form,
        socket.assigns.data_target_info_form,
        socket.assigns.report_form
      ]
      |> Enum.all?(&valid?/1)

    socket
    |> assign(:valid?, valid?)
  end

  defp valid?(%Phoenix.HTML.Form{source: source}), do: source.valid?
  defp valid?(_), do: false
end
