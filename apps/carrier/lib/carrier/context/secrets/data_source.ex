defmodule Carrier.Secrets.DataSource do
  use Carrier.Schema
  alias Carrier.Secrets.ConnInfo

  @derive Carrier.Obfuscatable.Protocol

  schema "data_sources" do
    belongs_to :conn_info, ConnInfo

    field :org_id, :id
    field :source, Ecto.Enum, values: [:postgres, :mysql, :bigquery, :athena, :tableau]
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
    |> where([ds], is_nil(ds.deleted_at))
  end

  def fetch(id) do
    __MODULE__
    |> where([ds], ds.id == ^id)
    |> where([ds], is_nil(ds.deleted_at))
  end

  def preload_conn_info(query) do
    query |> preload([:conn_info])
  end
end
