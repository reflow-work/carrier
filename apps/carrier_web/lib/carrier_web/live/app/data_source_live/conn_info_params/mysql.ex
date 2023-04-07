defmodule CarrierWeb.App.DataSourceLive.New.ConnInfoParams.MySQL do
  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field :org_id, :id
    field :name, :string
    field :source, Ecto.Enum, values: [:mysql], default: :mysql

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
    |> cast_embed(:conn_info, with: &changeset_for_conn_info/2, required: true)
  end

  @required_for_conn_info [:hostname, :port, :database, :username, :password, :ssl]
  defp changeset_for_conn_info(%__MODULE__.ConnInfo{} = struct, attrs) do
    struct
    |> cast(attrs, @required_for_conn_info)
    |> validate_required(@required_for_conn_info)
  end

  def init_attrs() do
    %{conn_info: %{port: 3306, ssl: false}}
  end
end
