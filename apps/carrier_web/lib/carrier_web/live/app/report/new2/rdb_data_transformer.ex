defmodule CarrierWeb.App.ReportLive.New2.RDBDataTransformer do
  use CarrierWeb, :live_component
  use Carrier.{Integrations, Data}
  alias CarrierWeb.App.ReportLive.New2.DataSourceInfoParams
  alias CarrierWeb.App.ReportLive.New2.RDBQuerier
  alias Doumi.Phoenix.Params

  @impl true
  def mount(socket) do
    socket =
      socket
      |> assign(:sql_template, "")
      |> assign(:query_result, nil)

    {:ok, socket}
  end

  # init
  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)

    validate_and_send_data_source_info_form(socket)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.live_component
        module={RDBQuerier}
        id="rdb_querier"
        data_source={@data_source}
        onchange={
          fn sql_template, query_result ->
            send_update(__MODULE__, id: @id, sql_template: sql_template, query_result: query_result)
          end
        }
      />
    </div>
    """
  end

  defp validate_and_send_data_source_info_form(socket) do
    %DataSource{id: data_source_id, source: source} = socket.assigns.data_source

    data_source_info_input = %{
      data_source_id: data_source_id,
      source: source,
      params: %{}
    }

    data_source_info_form = DataSourceInfoParams.to_form(data_source_info_input)

    send(self(), {:update, {:data_source_info_form, data_source_info_form}})
  end
end
