defmodule Carrier.Billing.Subscription do
  use Carrier.Schema
  alias Carrier.Billing.Plan
  alias Carrier.Payments.Payment

  schema "subscriptions" do
    belongs_to :plan, Plan
    belongs_to :payment, Payment
    belongs_to :prev_subscription, __MODULE__

    field :org_id, :id
    field :start_on, :utc_datetime_usec
    field :end_on, :utc_datetime_usec
    field :status, Ecto.Enum, values: [:pending, :active, :expired, :canceled], default: :pending

    field :activated_at, :utc_datetime_usec
    field :expired_at, :utc_datetime_usec

    timestamps()
  end

  # TODO: implement it
  def create(_params) do
    %__MODULE__{}
  end

  # TODO: implement it
  def activate(%__MODULE__{status: :pending} = subscription) do
    subscription
  end

  # TODO: implement it
  def expire(%__MODULE__{status: :active} = subscription) do
    subscription
  end
end
