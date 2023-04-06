defmodule Carrier.Payments.CreditCard do
  use Carrier.Schema

  schema "credit_cards" do
    field :org_id, :id
    field :provider, Ecto.Enum, values: [:toss_payments]
    field :billing_key, :string
    field :customer_key, :string
    field :card_company, :string
    field :card_number, :string
    field :deleted_at, :utc_datetime_usec

    timestamps()
  end
end
