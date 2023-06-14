defmodule CarrierWeb.App.ReportLive.New2.Components do
  use CarrierWeb, :component
  use Carrier.Integrations
  import Carrier.Data.Source.RDB.Guard

  embed_templates "*"

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
            <.simple_form for={@report_form} phx-change="validate_report">
              <.input
                type="text"
                field={@report_form[:name]}
                label="리포트 이름"
                label_align={:left}
                placeholder="데일리 유저 지표"
              />
              <.input
                type="hidden"
                field={@report_form[:text]}
                label="리포트 텍스트"
                phx-hook="TrixEditor"
              />
              <div id={"#{@report_form[:text].id}-editor"} phx-update="ignore">
                <trix-editor input={@report_form[:text].id}></trix-editor>
              </div>
              <.input
                type="select"
                field={@report_form[:interval]}
                label="발송 주기"
                label_align={:left}
                options={interval_options()}
              />
              <.input
                class={@report_form[:interval].value != :weekly && "hidden"}
                type="select"
                field={@report_form[:trigger_weekday]}
                label="발송 요일"
                label_align={:left}
                options={trigger_weekday_options()}
                value={@report_form[:trigger_weekday].value}
              />
              <.input
                class={@report_form[:interval].value not in [:daily, :weekly] && "hidden"}
                type="select"
                field={@report_form[:trigger_time]}
                label="발송 시간"
                label_align={:left}
                options={trigger_time_options()}
                value={@report_form[:trigger_time].value}
              />
            </.simple_form>
          </div>
        </.card>
      </.card_container>
    </div>
    """
  end

  defp interval_options() do
    [
      {"매시간", :hourly},
      {"매일", :daily},
      {"매주", :weekly}
    ]
  end

  defp trigger_time_options() do
    [
      {"자정", "00:00:00"},
      {"오전 1시", "01:00:00"},
      {"오전 2시", "02:00:00"},
      {"오전 3시", "03:00:00"},
      {"오전 4시", "04:00:00"},
      {"오전 5시", "05:00:00"},
      {"오전 6시", "06:00:00"},
      {"오전 7시", "07:00:00"},
      {"오전 8시", "08:00:00"},
      {"오전 9시", "09:00:00"},
      {"오전 10시", "10:00:00"},
      {"오전 11시", "11:00:00"},
      {"정오", "12:00:00"},
      {"오후 1시", "13:00:00"},
      {"오후 2시", "14:00:00"},
      {"오후 3시", "15:00:00"},
      {"오후 4시", "16:00:00"},
      {"오후 5시", "17:00:00"},
      {"오후 6시", "18:00:00"},
      {"오후 7시", "19:00:00"},
      {"오후 8시", "20:00:00"},
      {"오후 9시", "21:00:00"},
      {"오후 10시", "22:00:00"},
      {"오후 11시", "23:00:00"}
    ]
  end

  defp trigger_weekday_options() do
    [
      {"월요일", 1},
      {"화요일", 2},
      {"수요일", 3},
      {"목요일", 4},
      {"금요일", 5},
      {"토요일", 6},
      {"일요일", 7}
    ]
  end
end
