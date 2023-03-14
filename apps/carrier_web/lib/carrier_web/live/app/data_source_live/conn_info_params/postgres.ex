defmodule CarrierWeb.App.DataSourceLive.New.ConnInfoParams.Postgres do
  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field :org_id, :integer
    field :name, :string
    field :source, Ecto.Enum, values: [:postgres], default: :postgres

    embeds_one :conn_info, ConnInfo, primary_key: false do
      field :hostname, :string
      field :port, :integer
      field :database, :string
      field :username, :string
      field :password, :string
      field :ssl, :boolean
    end
  end

  @required [:org_id, :name]
  def changeset(%__MODULE__{} = struct \\ %__MODULE__{}, attrs) do
    struct
    |> cast(attrs, @required)
    |> validate_required(@required)
    |> cast_embed(:conn_info, with: &changeset_for_conn_info/2)
  end

  @required_for_conn_info [:hostname, :port, :database, :username, :password, :ssl]
  defp changeset_for_conn_info(%__MODULE__.ConnInfo{} = struct, attrs) do
    struct
    |> cast(attrs, @required_for_conn_info)
    |> validate_required(@required_for_conn_info)
  end

  def init_attrs() do
    %{conn_info: %{port: 5432, ssl: false}}
  end
end
