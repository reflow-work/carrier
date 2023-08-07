defmodule CarrierWeb.App.ReportLive.New2.RedashParams do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    embeds_many :dashboards, Dashboard, primary_key: false, on_replace: :delete do
      field :id, :string
    end
  end

  @required []
  def changeset(%__MODULE__{} = struct \\ %__MODULE__{}, attrs) do
    struct
    |> cast(attrs, @required)
    |> cast_embed(:dashboards, required: true, with: &changeset_dashboard/2)
    |> validate_length(:dashboards, min: 1)
  end

  @required_dashboard [:id]
  defp changeset_dashboard(%__MODULE__.Dashboard{} = struct, attrs) do
    struct
    |> cast(attrs, @required_dashboard)
    |> validate_required(@required_dashboard)
  end
end
