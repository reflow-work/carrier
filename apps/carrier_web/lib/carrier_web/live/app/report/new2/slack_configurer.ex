defmodule CarrierWeb.App.ReportLive.New2.SlackConfigurer do
  use CarrierWeb, :live_component
  use Carrier.Integrations
  alias Carrier.Data.Target.Slack

  @impl true
  def mount(socket) do
    {:ok, socket}
  end

  @impl true
  def update(%{data_target: %DataTarget{conn_info: %ConnInfo{} = conn_info}} = assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign_async(
        :channels,
        fn ->
          {:ok, channels} =
            conn_info
            |> ConnInfo.to_credentials()
            |> Slack.list_channels()

          channels
        end,
        __MODULE__
      )

    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.card_container>
        <.card>
          <div>
            <.card_title title="Slack 설정하기" />
          </div>

          <div class="max-w-md">
            <.loading :if={@channels.loading?} />
            <.live_component
              :if={!@channels.loading?}
              module={Search}
              id="slack_channel_selector"
              label="Channel 이름"
              label_align={:left}
              poition={:top}
              items={@channels.value |> Enum.map(fn %{id: id, name: name} -> {"# #{name}", id} end)}
              multiple={false}
              duplicatable={true}
              onchange={
                fn [selected_channel_id] ->
                  send_update(__MODULE__, id: @id, selected_channel_id: selected_channel_id)
                end
              }
            />
          </div>
        </.card>
      </.card_container>
    </div>
    """
  end
end
