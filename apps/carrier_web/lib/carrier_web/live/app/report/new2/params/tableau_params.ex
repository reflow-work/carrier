defmodule CarrierWeb.App.ReportLive.New2.TableauParams do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    embeds_many :views, View, primary_key: false, on_replace: :delete do
      field :id, :string
    end
  end

  @required []
  def changeset(%__MODULE__{} = struct \\ %__MODULE__{}, attrs) do
    struct
    |> cast(attrs, @required)
    |> cast_embed(:views, required: true, with: &changeset_view/2)
    |> validate_length(:views, min: 1)
  end

  @required_view [:id]
  defp changeset_view(%__MODULE__.View{} = struct, attrs) do
    struct
    |> cast(attrs, @required_view)
    |> validate_required(@required_view)
  end
end
