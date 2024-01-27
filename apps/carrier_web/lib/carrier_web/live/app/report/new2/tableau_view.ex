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
          view: %Tableau.View{id: view_id, workbook_id: workbook_id}
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
            Tableau.get_view_preview_image_binary(
              workbook_id,
              view_id,
              data_source
            )
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
      <div :if={@image_binary.valid?} class="max-h-40 max-w-md overflow-hidden border rounded mt-2">
        <img src={"data:image/png;base64,#{@image_binary.value |> Base.encode64()}"} />
      </div>
      <.error :if={@image_binary.error}><%= inspect(@image_binary.error) %></.error>
    </div>
    """
  end
end
