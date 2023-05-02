defmodule CarrierWeb.App.ReportLive.New2.TableauView do
  use CarrierWeb, :live_component
  use Carrier.Secrets
  alias Carrier.Data.Source.Tableau
  alias Carrier.Core.Nillable

  @impl true
  def mount(socket) do
    {:ok, socket}
  end

  # init
  @impl true
  def update(
        %{
          data_source: %DataSource{conn_info: %ConnInfo{} = conn_info},
          view: %Tableau.View{id: view_id}
        } = assigns,
        socket
      ) do
    socket =
      socket
      |> assign(assigns)
      |> Nillable.run_until(socket.assigns[:image_binary], fn socket ->
        socket
        |> assign_async(
          :image_binary,
          fn ->
            {:ok, image_binary} =
              Tableau.get_view_image_binary(view_id, ConnInfo.to_credentials(conn_info))

            image_binary
          end,
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
      <p><%= @view.name %></p>
      <.icon :if={@image_binary.loading?} name="hero-arrow-path" class="mt-4 w-6 h-6 animate-spin" />
      <img
        :if={!@image_binary.loading?}
        src={"data:image/png;base64,#{@image_binary.value |> Base.encode64()}"}
      />
    </div>
    """
  end
end
