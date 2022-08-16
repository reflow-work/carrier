defmodule Carrier.Reports.Report do
  use Carrier.Schema
  alias Carrier.TenantRepo

  schema "reports" do
    field :org_id, :integer
    field :name, :string

    timestamps()
  end

  @required_for_create [:org_id, :name]
  defp changeset_for_create(%__MODULE__{} = struct, attrs) do
    struct
    |> cast(attrs, @required_for_create)
    |> validate_required(@required_for_create)
  end

  def create(%{org_id: org_id, name: name}) do
    %__MODULE__{}
    |> changeset_for_create(%{org_id: org_id, name: name})
  end

  def list() do
    __MODULE__
  end
end
