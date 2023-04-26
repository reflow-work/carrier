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

    field :provider, Ecto.Enum, values: [:toss_payments]
    field :provider_key, :string
    field :item, :string
    field :payload, :map

    timestamps()
  end

  @required_for_create [:org_id, :credit_card_id, :amount, :currency]
  defp changeset_for_create(%__MODULE__{} = struct, attrs) do
    struct
    |> cast(attrs, @required_for_create)
    |> validate_required(@required_for_create)
  end

  @required_for_confirm [:status, :confirmed_at, :provider, :provider_key, :item, :payload]
  defp changeset_for_confirm(%__MODULE__{} = struct, attrs) do
    struct
    |> cast(attrs, @required_for_confirm)
    |> validate_required(@required_for_confirm)
  end

  @required_for_fail [:status, :failed_at, :payload]
  defp changeset_for_fail(%__MODULE__{} = struct, attrs) do
    struct
    |> cast(attrs, @required_for_fail)
    |> validate_required(@required_for_fail)
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

  def confirm(%__MODULE__{} = struct, %{
        confirmed_at: confirmed_at,
        provider: provider,
        provider_key: provider_key,
        item: item,
        payload: payload
      }) do
    struct
    |> changeset_for_confirm(%{
      status: :confirmed,
      confirmed_at: confirmed_at,
      provider: provider,
      provider_key: provider_key,
      item: item,
      payload: payload
    })
  end

  def fail(%__MODULE__{} = struct, %{failed_at: failed_at, payload: payload}) do
    struct
    |> changeset_for_fail(%{
      status: :failed,
      failed_at: failed_at,
      payload: payload
    })
  end
end
