defmodule Carrier.Integrations.Webhook do
  use Carrier.Schema
  alias Carrier.Integrations.DataSource

  schema "webhooks" do
    belongs_to :data_source, DataSource

    field :org_id, :id
    field :key, :string
  end

  @required_for_create [:org_id, :data_source_id, :key]
  defp changeset_for_create(%__MODULE__{} = struct, attrs) do
    struct
    |> cast(attrs, @required_for_create)
    |> validate_required(@required_for_create)
  end

  def create(attrs) do
    %__MODULE__{}
    |> changeset_for_create(attrs)
  end
end
