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

  @required [:org_id, :credit_card_id, :amount, :currency]
  defp changeset_for_create(%__MODULE__{} = struct, attrs) do
    struct
    |> cast(attrs, @required)
    |> validate_required(@required)
  end

  def create(%{org_id: org_id, credit_card_id: credit_card_id, amount: amount, currency: currency}) do
    %__MODULE__{}
    |> changeset_for_create(%{
      org_id: org_id,
      credit_card_id: credit_card_id,
      amount: amount,
      currency: currency
    })
  end
end
