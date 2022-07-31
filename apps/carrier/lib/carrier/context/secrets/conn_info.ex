defmodule Carrier.Secrets.ConnInfo do
  use Carrier.Schema
  alias Carrier.Secrets.Types

  schema "conn_infos" do
    field :org_id, :integer
    field :name, :string
    field :source, :string
    field :info, Types.Map, source: :encrypted_info, redact: true
  end

  @required_for_create [:org_id, :name, :source, :info]
  def changeset_for_create(%__MODULE__{} = struct, attrs) do
    struct
    |> cast(attrs, @required_for_create)
    |> validate_required(@required_for_create)
  end

  def create(attrs) do
    %__MODULE__{}
    |> changeset_for_create(attrs)
  end

  def list() do
    __MODULE__
  end

  def fetch(id) do
    __MODULE__
    |> where([ci], ci.id == ^id)
  end
end
