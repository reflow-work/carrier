defmodule CarrierWeb.App.ReportLive.New2.Components do
  use CarrierWeb, :component
  use Carrier.Integrations
  import Carrier.Data.Source.RDB.Guard
  alias Carrier.Core.Nillable

  embed_templates "*"

  attr :data_sources, :list, required: true
  attr :selected_data_source, :any, required: true
  attr :onselect, :any, required: true

  def data_source_selector(assigns)

  defp data_source_options(data_sources) do
    data_sources
    |> Enum.map(fn %DataSource{id: id, name: name} -> {name, id} end)
  end

  attr :data_source, :any, required: true
  attr :data_source_info, :any

  def data_transformer(assigns) do
    case assigns.data_source do
      nil ->
        empty_data_transformer(assigns)

      %DataSource{source: source} ->
        module =
          case source do
            source when is_rdb_source(source) -> CarrierWeb.App.ReportLive.New2.RDBDataTransformer
            :tableau -> CarrierWeb.App.ReportLive.New2.TableauDataTransformer
          end

        assigns =
          assigns
          |> assign(:module, module)

        ~H"""
        <.live_component
          module={@module}
          id="data_transformer"
          data_source={@data_source}
          data_source_info={@data_source_info}
        />
        """

      _ ->
        ~H"""
        Not implemented
        """
    end
  end

  attr :data_target, :any
  attr :data_target_info, :any

  def data_target_configurer(assigns) do
    case assigns.data_target do
      %DataTarget{service_name: :slack} ->
        ~H"""
        <.live_component
          module={CarrierWeb.App.ReportLive.New2.SlackConfigurer}
          id="slack_configurer"
          data_target={@data_target}
          data_target_info={@data_target_info}
        />
        """
    end
  end

  attr :report_form, :any, required: true
  attr :valid?, :boolean, required: true

  def report_configurer(assigns) do
    ~H"""
    <div>
      <.card_container>
        <.card>
          <.card_title title="리포트 설정하기" />
          <div class="max-w-md">
            <.simple_form for={@report_form} phx-change="validate_report" phx-submit="create_report">
              <.input
                type="text"
                field={@report_form[:name]}
                label="리포트 이름"
                label_align={:left}
                placeholder="데일리 유저 지표"
              />
              <.input
                type="select"
                field={@report_form[:interval]}
                label="발송 주기"
                label_align={:left}
                options={interval_options()}
                value={:daily}
              />
              <.input
                type="select"
                field={@report_form[:trigger_time]}
                label="발송 시간"
                label_align={:left}
                options={hours()}
                value="00:00"
              />
            </.simple_form>
          </div>
        </.card>
      </.card_container>
    </div>
    """
  end

  defp interval_options() do
    [{"매일", :daily}]
  end

  defp hours() do
    [
      {"자정", "00:00"},
      {"오전 1시", "01:00"},
      {"오전 2시", "02:00"},
      {"오전 3시", "03:00"},
      {"오전 4시", "04:00"},
      {"오전 5시", "05:00"},
      {"오전 6시", "06:00"},
      {"오전 7시", "07:00"},
      {"오전 8시", "08:00"},
      {"오전 9시", "09:00"},
      {"오전 10시", "10:00"},
      {"오전 11시", "11:00"},
      {"정오", "12:00"},
      {"오후 1시", "13:00"},
      {"오후 2시", "14:00"},
      {"오후 3시", "15:00"},
      {"오후 4시", "16:00"},
      {"오후 5시", "17:00"},
      {"오후 6시", "18:00"},
      {"오후 7시", "19:00"},
      {"오후 8시", "20:00"},
      {"오후 9시", "21:00"},
      {"오후 10시", "22:00"},
      {"오후 11시", "23:00"}
    ]
  end
end
