defmodule CarrierWeb.App.ReportLive.New2.AmplitudeParams do
  use Ecto.Schema
  use Doumi.Phoenix.Params, as: :amplitude
  import Ecto.Changeset
  alias Carrier.Data.Source.Amplitude

  @primary_key false
  embedded_schema do
    embeds_many :dashboards, Dashboard, primary_key: false, on_replace: :delete do
      field :name, :string
      field :url, :string
    end
  end

  @required []
  def changeset(%__MODULE__{} = struct \\ %__MODULE__{}, attrs) do
    struct
    |> cast(attrs, @required)
    |> cast_embed(:dashboards,
      with: &changeset_dashboard/2,
      sort_param: :dashboard_order,
      drop_param: :dashboard_delete,
      required: true
    )
    |> validate_length(:dashboards, min: 1)
  end

  @required_dashboard [:name, :url]
  defp changeset_dashboard(%__MODULE__.Dashboard{} = struct, attrs) do
    struct
    |> cast(attrs, @required_dashboard)
    |> validate_required(@required_dashboard)
    |> validate_format(:url, Amplitude.dashboard_url_format())
  end
end
