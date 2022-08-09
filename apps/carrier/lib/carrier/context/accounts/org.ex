defmodule Carrier.Accounts.Org do
  use Carrier.Schema

  @primary_key {:org_id, :id, autogenerate: true}
  schema "orgs" do
    field :name, :string
  end

  @required_for_create [:name]
  defp changeset_for_create(%__MODULE__{} = struct, attrs) do
    struct
    |> cast(attrs, @required_for_create)
  end

  def create(%{name: name}) do
    %__MODULE__{}
    |> changeset_for_create(%{name: name})
  end
end
