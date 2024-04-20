defmodule CarrierWeb.App.ReportLive.New2.RedashDashboard do
  use CarrierWeb, :live_component
  use Carrier.Integrations
  alias Carrier.Data.Source.Redash
  alias Carrier.Core.Nillable

  @impl true
  def mount(socket) do
    {:ok, socket}
  end

  # init
  @impl true
  def update(
        %{
          data_source: %DataSource{} = data_source,
          dashboard: %Redash.Dashboard{slug: dashboard_slug}
        } = assigns,
        socket
      ) do
    socket =
      socket
      |> assign(assigns)
      |> Nillable.run_until(socket.assigns[:image_binary], fn socket ->
        socket
        |> AssignHelper.assign_async(
          :image_binary,
          fn -> Redash.get_dashboard_image_binary(data_source, dashboard_slug) end,
          __MODULE__
        )
      end)

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
      <p><%= @dashboard.name %></p>
      <.loading :if={@image_binary.loading?} />
      <div :if={@image_binary.valid?} class="max-h-40 max-w-md overflow-hidden border rounded mt-2">
        <img src={"data:image/png;base64,#{@image_binary.value |> Base.encode64()}"} />
      </div>
      <.error :if={@image_binary.error}><%= @image_binary.error %></.error>
    </div>
    """
  end
end
