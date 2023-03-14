defmodule CarrierWeb.App.DataSourceLive.New.ConnInfoParams.BigQuery do
  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field :org_id, :integer
    field :name, :string
    field :source, Ecto.Enum, values: [:bigquery], default: :bigquery

    embeds_one :conn_info, ConnInfo, primary_key: false do
      field :project_id, :string
      field :credentials_json, :string
    end
  end

  @required [:org_id, :name]
  def changeset(%__MODULE__{} = struct \\ %__MODULE__{}, attrs) do
    struct
    |> cast(attrs, @required)
    |> validate_required(@required)
    |> cast_embed(:conn_info, with: &changeset_for_conn_info/2)
  end

  @required_for_conn_info [:project_id, :credentials_json]
  defp changeset_for_conn_info(%__MODULE__.ConnInfo{} = struct, attrs) do
    struct
    |> cast(attrs, @required_for_conn_info)
    |> validate_required(@required_for_conn_info)
  end

  def init_attrs() do
    %{conn_info: %{}}
  end
end
