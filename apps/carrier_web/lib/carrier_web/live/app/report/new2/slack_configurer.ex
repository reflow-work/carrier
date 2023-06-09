defmodule CarrierWeb.App.ReportLive.New2.SlackConfigurer do
  use CarrierWeb, :live_component
  use Carrier.{Integrations, Reports}
  alias Carrier.Data.Target.Slack
  alias Carrier.Core.Nillable

  @impl true
  def mount(socket) do
    socket =
      socket
      |> assign(:selected_channel_id, nil)
      |> assign(:selected_channel, nil)

    {:ok, socket}
  end

  # init
  @impl true
  def update(
        %{data_target: %DataTarget{} = data_target, data_target_info: data_target_info} = assigns,
        socket
      ) do
    socket =
      socket
      |> assign(assigns)
      |> assign_async(
        :channels,
        fn ->
          credentials = data_target |> DataTarget.to_credentials()

          {:ok, channels} = Slack.list_channels(credentials)
          {:ok, users} = Slack.list_users(credentials)

          channels
          |> Enum.map(&Slack.Channel.update_user_name(&1, users))
        end,
        __MODULE__
      )

    socket =
      case data_target_info do
        nil ->
          socket

        %{params: %{channel_id: channel_id}} ->
          socket
          |> assign(:selected_channel_id, channel_id)
      end

    validate_and_send_data_target_info_form(socket)

    {:ok, socket}
  end

  # update by async update
  @impl true
  def update(%{channels: channels}, socket) do
    socket =
      socket
      |> assign(:channels, channels)

    if socket.assigns.selected_channel_id do
      send_update(Search,
        id: "slack_channel_selector",
        selected_item_value: socket.assigns.selected_channel_id
      )
    end

    validate_and_send_data_target_info_form(socket)

    {:ok, socket}
  end

  # update by search
  @impl true
  def update(%{selected_channel_id: selected_channel_id}, socket) do
    selected_channel =
      socket.assigns.channels.value
      |> Nillable.map(fn channels ->
        channels
        |> Enum.find(&(&1.id == selected_channel_id))
      end)

    socket =
      socket
      |> assign(:selected_channel, selected_channel)

    validate_and_send_data_target_info_form(socket)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.card_container>
        <.card class="z-10">
          <div>
            <.card_title title="Slack 발송 설정하기" />
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

  defp validate_and_send_data_target_info_form(socket) do
    data_target_info_input = %{
      data_target_id: socket.assigns.data_target.id,
      target: :slack,
      params:
        socket.assigns.selected_channel
        |> Nillable.map(fn %{id: id, name: name} ->
          %{
            channel_id: id,
            channel_name: name
          }
        end)
    }

    data_target_info_form = DataTargetInfo.to_form(data_target_info_input)

    send(self(), {:update, {:data_target_info_form, data_target_info_form}})
  end
end
