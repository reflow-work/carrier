defmodule Carrier.Payments.Payment do
  use Carrier.Schema

  schema "payments" do
    belongs_to :credit_card, Carrier.Payments.CreditCard
    has_one :subscription, Carrier.Billing.Subscription

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

    field :deleted_at, :utc_datetime_usec

    timestamps()
  end

  @required_for_create [:org_id, :amount, :currency]
  defp changeset_for_create(%__MODULE__{} = struct, attrs) do
    struct
    |> cast(attrs, @required_for_create)
    |> validate_required(@required_for_create)
  end

  @required_for_confirm [
    :credit_card_id,
    :status,
    :confirmed_at,
    :provider,
    :provider_key,
    :item,
    :payload
  ]
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

  def list_confirmed() do
    __MODULE__
    |> where([p], p.status == :confirmed)
    |> where_not_deleted()
    |> order_by([p], desc: p.confirmed_at)
  end

  def fetch(payment_id) do
    __MODULE__
    |> where([p], p.id == ^payment_id)
    |> where_not_deleted()
  end

  def create(params) do
    %__MODULE__{}
    |> changeset_for_create(params)
  end

  def confirm(%__MODULE__{} = struct, params) do
    struct
    |> changeset_for_confirm(params |> Map.put(:status, :confirmed))
  end

  def fail(%__MODULE__{} = struct, params) do
    struct
    |> changeset_for_fail(params |> Map.put(:status, :failed))
  end
end
