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

  @required_for_create [:org_id, :plan_id, :start_on, :end_on]
  @optional_for_create [:prev_subscription_id]
  defp changeset_for_create(%__MODULE__{} = struct, attrs) do
    struct
    |> cast(attrs, @required_for_create ++ @optional_for_create)
    |> validate_required(@required_for_create)
    |> foreign_key_constraint(:plan_id)
    |> foreign_key_constraint(:prev_subscription_id)
  end

  def create(params) do
    %__MODULE__{}
    |> changeset_for_create(params)
  end

  def list_include_deleted() do
    __MODULE__
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
