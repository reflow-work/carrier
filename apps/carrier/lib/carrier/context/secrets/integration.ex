defmodule Carrier.Secrets.Integration do
  use Carrier.Schema

  schema "integrations" do
    field :org_id, :integer
    field :service_name, Ecto.Enum, values: [:slack]
    field :conn_info_id, :integer
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
  end
end
