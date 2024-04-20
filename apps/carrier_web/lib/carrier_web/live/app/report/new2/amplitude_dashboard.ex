defmodule CarrierWeb.App.ReportLive.New2.AmplitudeDashboard do
  use CarrierWeb, :live_component
  use Carrier.Integrations
  alias Carrier.Data.Source.Amplitude

  @impl true
  def mount(socket) do
    socket =
      socket
      |> assign(:dashboard_url, nil)
      |> assign(:image_binary, %{loading?: false, valid?: false, value: nil, error: nil})

    {:ok, socket}
  end

  # init
  @impl true
  def update(
        %{
          data_source: %DataSource{} = data_source,
          dashboard: %Amplitude.Dashboard{url: dashboard_url}
        } = assigns,
        socket
      ) do
    socket =
      socket
      |> assign(assigns)

    socket =
      case socket.assigns.dashboard_url != dashboard_url do
        true ->
          socket =
            socket
            |> assign(:dashboard_url, dashboard_url)

          socket =
            case Amplitude.validate_dashboard_url(dashboard_url) do
              true ->
                socket
                |> AssignHelper.assign_async(
                  :image_binary,
                  fn -> Amplitude.get_dashboard_image_binary(data_source, dashboard_url) end,
                  __MODULE__
                )

              false ->
                socket
            end

          socket

        false ->
          socket
      end

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
      <.loading :if={@image_binary.loading?} />
      <div :if={@image_binary.valid?} class="max-h-40 max-w-md overflow-hidden border rounded mt-2">
        <img src={"data:image/png;base64,#{@image_binary.value |> Base.encode64()}"} />
      </div>
      <.error :if={@image_binary.error}><%= @image_binary.error %></.error>
    </div>
    """
  end
end
