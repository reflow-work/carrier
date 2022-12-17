defmodule Carrier.Secrets.DataSource do
  use Carrier.Schema
  alias Carrier.Secrets.ConnInfo

  schema "data_sources" do
    belongs_to :conn_info, ConnInfo

    field :org_id, :id
    field :source, Ecto.Enum, values: [:postgres, :mysql]
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

  def tables_query(%__MODULE__{source: source}) do
    ConnInfo.Info.get_module(source).tables_query()
  end

  def table_name_field(%__MODULE__{source: source}) do
    ConnInfo.Info.get_module(source).table_name_field()
  end

  def columns_query(%__MODULE__{source: source}) do
    ConnInfo.Info.get_module(source).columns_query()
  end

  def column_name_field(%__MODULE__{source: source}) do
    ConnInfo.Info.get_module(source).column_name_field()
  end

  def data_type_field(%__MODULE__{source: source}) do
    ConnInfo.Info.get_module(source).data_type_field()
  end

  def is_date_type?(%__MODULE__{source: source}, type) do
    ConnInfo.Info.get_module(source).is_date_type?(type)
  end
end
