defmodule CarrierWeb.App.DataSourceLive.New.ConnInfoParams.Athena do
  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field :org_id, :integer
    field :name, :string
    field :source, Ecto.Enum, values: [:athena], default: :athena

    embeds_one :conn_info, ConnInfo, primary_key: false do
      field :access_key_id, :string
      field :secret_access_key, :string
      field :region, :string
      field :workgroup, :string
      field :database, :string
    end
  end

  @required [:org_id, :name]
  def changeset(%__MODULE__{} = struct \\ %__MODULE__{}, attrs) do
    struct
    |> cast(attrs, @required)
    |> validate_required(@required)
    |> cast_embed(:conn_info, with: &changeset_for_conn_info/2, required: true)
  end

  @required_for_conn_info [
    :access_key_id,
    :secret_access_key,
    :region,
    :workgroup,
    :database
  ]
  defp changeset_for_conn_info(%__MODULE__.ConnInfo{} = struct, attrs) do
    struct
    |> cast(attrs, @required_for_conn_info)
    |> validate_required(@required_for_conn_info)
  end

  def init_attrs() do
    %{conn_info: %{}}
  end
end
