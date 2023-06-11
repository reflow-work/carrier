defmodule Carrier.Integrations.DataTarget do
  use Carrier.Schema
  alias Carrier.Integrations.ConnInfo

  @derive Carrier.Obfuscatable.Protocol

  schema "data_targets" do
    belongs_to :conn_info, ConnInfo

    field :org_id, :id
    field :service_name, Ecto.Enum, values: [:slack]

    field :needs_update, :boolean
    field :deleted_at, :utc_datetime_usec
  end

  @required_for_create [:org_id, :service_name, :conn_info_id]
  defp changeset_for_create(%__MODULE__{} = struct, attrs) do
    struct
    |> cast(attrs, @required_for_create)
    |> validate_required(@required_for_create)
    |> unique_constraint([:org_id, :service_name],
      name: :conn_infos_org_id_service_name_index,
      error_key: :service_name
    )
    |> foreign_key_constraint(:conn_info_id)
  end

  def create(%{org_id: org_id, service_name: service_name, conn_info_id: conn_info_id}) do
    %__MODULE__{}
    |> changeset_for_create(%{
      org_id: org_id,
      service_name: service_name,
      conn_info_id: conn_info_id
    })
  end

  def list() do
    __MODULE__
    |> where_not_deleted()
  end

  def fetch(id) do
    __MODULE__
    |> where([i], i.id == ^id)
    |> where_not_deleted()
  end

  def preload_conn_info(query) do
    query |> preload([:conn_info])
  end

  def to_credentials(%__MODULE__{conn_info: %ConnInfo{} = conn_info}) do
    ConnInfo.to_credentials(conn_info)
  end
end
