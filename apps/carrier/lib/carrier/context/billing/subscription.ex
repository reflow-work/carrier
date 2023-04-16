defmodule Carrier.Billing.Subscription do
  use Carrier.Schema
  alias Carrier.Billing.Plan
  alias Carrier.Payments.Payment

  schema "subscriptions" do
    belongs_to :plan, Plan
    belongs_to :payment, Payment
    belongs_to :origin_subscription, __MODULE__

    field :org_id, :id
    field :extension_count, :integer
    field :start_on, :utc_datetime_usec
    field :end_on, :utc_datetime_usec
    field :status, Ecto.Enum, values: [:pending, :active, :expired, :cancelled], default: :pending

    field :activated_at, :utc_datetime_usec
    field :expired_at, :utc_datetime_usec

    timestamps()
  end

  @required_for_create [:org_id, :plan_id, :start_on, :end_on, :extension_count]
  @optional_for_create [:origin_subscription_id]
  defp changeset_for_create(%__MODULE__{} = struct, attrs) do
    struct
    |> cast(attrs, @required_for_create ++ @optional_for_create)
    |> validate_required(@required_for_create)
    |> foreign_key_constraint(:plan_id)
    |> unique_constraint(:status, name: :subscriptions_org_id_pending)
  end

  @required_for_activate [:status, :activated_at]
  @optional_for_activate [:payment_id]
  defp changeset_for_activate(%__MODULE__{} = struct, attrs) do
    struct
    |> cast(attrs, @required_for_activate ++ @optional_for_activate)
    |> validate_required(@required_for_activate)
    |> validate_inclusion(:status, [:active])
    |> foreign_key_constraint(:payment_id)
    |> unique_constraint(:status, name: :subscriptions_org_id_active)
  end

  @required_for_expire [:status, :expired_at]
  defp changeset_for_expire(%__MODULE__{} = struct, attrs) do
    struct
    |> cast(attrs, @required_for_expire)
    |> validate_required(@required_for_expire)
    |> validate_inclusion(:status, [:expired])
  end

  def create(params) do
    %__MODULE__{}
    |> changeset_for_create(params)
  end

  def list_include_deleted() do
    __MODULE__
  end

  def fetch(subscription_id) do
    __MODULE__
    |> where([s], s.id == ^subscription_id)
  end

  def fetch_with_state(subscription_id, state) do
    __MODULE__
    |> where([s], s.id == ^subscription_id)
    |> where([s], s.status == ^state)
  end

  # Assumtion: there is only one active subscription per org
  def fetch_active() do
    __MODULE__
    |> where([s], s.status == :active)
  end

  def activate(%__MODULE__{status: :pending} = struct, params) do
    struct
    |> changeset_for_activate(params |> Map.put(:status, :active))
  end

  def expire(%__MODULE__{status: :active} = struct, params) do
    struct
    |> changeset_for_expire(params |> Map.put(:status, :expired))
  end

  def get_info_for_next_subscription(%__MODULE__{
        id: subscription_id,
        origin_subscription_id: nil
      }) do
    %{origin_subscription_id: subscription_id}
  end

  def get_info_for_next_subscription(%__MODULE__{
        origin_subscription_id: origin_subscription_id
      }) do
    %{origin_subscription_id: origin_subscription_id}
  end
end
