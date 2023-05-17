defmodule CarrierWeb.App.ReportLive.New2.TableauView do
  use CarrierWeb, :live_component
  use Carrier.Integrations
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
          data_source: %DataSource{} = data_source,
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
              Tableau.get_view_image_binary(view_id, DataSource.to_credentials(data_source))

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
      <.loading :if={@image_binary.loading?} />
      <img
        :if={!@image_binary.loading?}
        src={"data:image/png;base64,#{@image_binary.value |> Base.encode64()}"}
      />
    </div>
    """
  end
end
