defmodule Carrier.Integrations.DataSource do
  use Carrier.Schema
  alias Carrier.Integrations.ConnInfo

  @derive Carrier.Obfuscatable.Protocol

  schema "data_sources" do
    belongs_to :conn_info, ConnInfo

    field :org_id, :id

    field :source, Ecto.Enum,
      values: [:postgres, :mysql, :bigquery, :athena, :tableau, :tableau_demo]

    field :name, :string

    field :deleted_at, :utc_datetime_usec
  end

  @required_for_create [:org_id, :name, :source, :conn_info_id]
  defp changeset_for_create(%__MODULE__{} = struct, attrs) do
    struct
    |> cast(attrs, @required_for_create)
    |> validate_required(@required_for_create)
    |> unique_constraint([:org_id, :name],
      name: :data_sources_org_id_name_index,
      error_key: :name
    )
    |> foreign_key_constraint(:conn_info_id)
  end

  def create(%{org_id: org_id, name: name, source: source, conn_info_id: conn_info_id}) do
    %__MODULE__{}
    |> changeset_for_create(%{
      org_id: org_id,
      name: name,
      source: source,
      conn_info_id: conn_info_id
    })
  end

  def list() do
    __MODULE__
    |> where_not_deleted()
  end

  def fetch(id) do
    __MODULE__
    |> where([ds], ds.id == ^id)
    |> where_not_deleted()
  end

  def preload_conn_info(query) do
    query |> preload([:conn_info])
  end

  def to_credentials(%__MODULE__{conn_info: %ConnInfo{} = conn_info}) do
    ConnInfo.to_credentials(conn_info)
  end

  def transl_source(source) do
    case source do
      :postgres -> "PostgreSQL"
      :mysql -> "MySQL"
      :bigquery -> "Google BigQuery"
      :athena -> "AWS Athena"
      :tableau -> "Tableau Cloud"
      :tableau_demo -> "(Demo)Tableau Cloud"
    end
  end

  def is_demo?(%__MODULE__{source: source}) do
    source in [:tableau_demo]
  end
end
