defmodule Carrier.Billing.Plan do
  use Carrier.Schema

  schema "plans" do
    field :billing_cycle, Ecto.Enum, values: [:none, :monthly, :yearly]
    field :name, :string
    field :type, Ecto.Enum, values: [:trial, :basic, :pro]
    field :price, :integer
    field :currency, Ecto.Enum, values: [:KRW]
    field :description, {:array, :string}
    field :subscribable, :boolean, default: false

    field :deleted_at, :utc_datetime_usec

    timestamps()
  end
end
