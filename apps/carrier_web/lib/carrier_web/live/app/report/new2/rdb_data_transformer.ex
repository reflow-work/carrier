defmodule CarrierWeb.App.ReportLive.New2.RDBDataTransformer do
  use CarrierWeb, :live_component
  use Carrier.Integrations
  alias CarrierWeb.App.ReportLive.New2.DataSourceInfoParams
  alias Doumi.Phoenix.Params

  @impl true
  def mount(socket) do
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
      <.card_container>
        <.card class="z-10">
          <div>
            <.card_title title="쿼리 입력하기" />
            <p class="mt-2">☝️ 기준이 되는 날짜 컬럼과 보고 싶은 지표 컬럼(최대 3개)을 쿼리해주세요.</p>
          </div>
          <div>
            <.simple_form for={%{}} phx-target={@myself} phx-submit="run_query">
              <.input type="textarea" name="query" value="" />
              <.button class="mt-2">쿼리 실행</.button>
            </.simple_form>
          </div>
        </.card>
      </.card_container>
    </div>
    """
  end

  @impl true
  def handle_event("run_query", %{"query" => _query}, socket) do
    {:noreply, socket}
  end

  defp validate_and_send_data_source_info_form(socket) do
    %DataSource{id: data_source_id, source: source} = socket.assigns.data_source

    data_source_info_input = %{
      data_source_id: data_source_id,
      source: source,
      params: %{}
    }

    data_source_info_form =
      Params.to_form(%DataSourceInfoParams{}, data_source_info_input, as: :data_source_info)

    send(self(), {:update, {:data_source_info_form, data_source_info_form}})
  end
end
