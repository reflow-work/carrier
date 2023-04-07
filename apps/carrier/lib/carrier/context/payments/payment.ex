defmodule Carrier.Payments.Payment do
  use Carrier.Schema

  schema "payments" do
    belongs_to :credit_card, Carrier.Payments.CreditCard

    field :org_id, :id
    field :amount, :decimal
    field :currency, Ecto.Enum, values: [:KRW]
    field :status, Ecto.Enum, values: [:pending, :confirmed, :failed], default: :pending

    field :confirmed_at, :utc_datetime_usec
    field :failed_at, :utc_datetime_usec
    field :payload, :map

    timestamps()
  end
end
