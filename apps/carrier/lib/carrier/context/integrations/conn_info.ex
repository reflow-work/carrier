defmodule Carrier.Integrations.ConnInfo do
  use Carrier.Schema
  alias Carrier.Integrations.Types
  alias Carrier.Integrations.ConnInfo

  schema "conn_infos" do
    field :org_id, :id
    field :name, :string

    field :source, Ecto.Enum,
      values: [:postgres, :mysql, :bigquery, :athena, :slack, :tableau]

    field :info, Types.Map, source: :encrypted_info, redact: true

    field :deleted_at, :utc_datetime_usec

    timestamps()
  end

  @required_for_create [:org_id, :name, :source, :info]
  def changeset_for_create(%__MODULE__{} = struct, attrs) do
    struct
    |> cast(attrs, @required_for_create)
    |> validate_required(@required_for_create)
    |> unique_constraint([:org_id, :name], name: :conn_infos_org_id_name_index, error_key: :name)
    |> validate_info()
  end

  @required_for_update_info [:info]
  def changeset_for_update_info(%__MODULE__{} = struct, attrs) do
    struct
    |> cast(attrs, @required_for_update_info)
    |> validate_required(@required_for_update_info)
    |> validate_info()
  end

  defp validate_info(%Ecto.Changeset{data: data, changes: changes} = changeset) do
    source =
      case {data, changes} do
        {_, %{source: source}} -> source
        {%{source: source}, _} -> source
      end

    validate_change(changeset, :info, fn :info, info ->
      info_changeset = ConnInfo.Info.get_changeset(source, info)

      case info_changeset.valid? do
        true -> []
        false -> info_changeset.errors
      end
    end)
  end

  def create(attrs) do
    %__MODULE__{}
    |> changeset_for_create(attrs)
  end

  def update_info(%__MODULE__{} = struct, attrs) do
    struct
    |> changeset_for_update_info(attrs)
  end

  def list() do
    __MODULE__
    |> where_not_deleted()
  end

  def fetch(id) do
    __MODULE__
    |> where([ci], ci.id == ^id)
    |> where_not_deleted()
  end

  def to_credentials(%__MODULE__{source: source, info: info}) do
    __MODULE__.Info.to_credentials(source, info)
  end
end
