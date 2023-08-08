defmodule CarrierWeb.Components.DataSourceNew.ConnInfoParams.Amplitude do
  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field :org_id, :id
    field :name, :string
    field :source, Ecto.Enum, values: [:amplitude], default: :amplitude

    embeds_one :conn_info, ConnInfo, primary_key: false do
    end
  end

  @required [:org_id, :name]
  def changeset(%__MODULE__{} = struct \\ %__MODULE__{}, attrs) do
    struct
    |> cast(attrs, @required)
    |> validate_required(@required)
    |> cast_embed(:conn_info, with: &changeset_for_conn_info/2, required: true)
  end

  @required_for_conn_info []
  defp changeset_for_conn_info(%__MODULE__.ConnInfo{} = struct, attrs) do
    struct
    |> cast(attrs, @required_for_conn_info)
    |> validate_required(@required_for_conn_info)
  end

  def init_attrs() do
    %{}
  end
end
