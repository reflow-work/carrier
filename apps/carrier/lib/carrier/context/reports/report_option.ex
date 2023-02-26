defmodule Carrier.Reports.ReportOption do
  use Carrier.Schema

  @derive Jason.Encoder
  @primary_key false
  embedded_schema do
    field :elements, {:array, Ecto.Enum}, values: [:text, :table, :chart]
  end

  @required_for_create [
    :elements
  ]
  def changeset_for_create(struct, attrs) do
    struct
    |> cast(attrs, @required_for_create)
    |> validate_required(@required_for_create)
  end
end
