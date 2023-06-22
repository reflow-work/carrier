defmodule CarrierWeb.Components.DataSourceNew.ConnInfoParams.TableauDemo do
  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field :org_id, :id
    field :name, :string
    field :source, Ecto.Enum, values: [:tableau_demo], default: :tableau_demo
    field :conn_info, :map, default: %{}
  end

  @required [:org_id, :name]
  def changeset(%__MODULE__{} = struct \\ %__MODULE__{}, attrs) do
    struct
    |> cast(attrs, @required)
    |> validate_required(@required)
  end

  def init_attrs() do
    %{}
  end
end
