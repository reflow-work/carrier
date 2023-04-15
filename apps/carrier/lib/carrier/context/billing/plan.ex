defmodule Carrier.Billing.Plan do
  use Carrier.Schema
  alias Carrier.Core.DateTimeHelper

  schema "plans" do
    field :billing_cycle, Ecto.Enum, values: [:none, :monthly, :yearly]
    field :name, :string
    field :type, Ecto.Enum, values: [:trial, :basic, :pro]
    field :price, :decimal
    field :currency, Ecto.Enum, values: [:KRW]
    field :description, {:array, :string}
    field :subscribable, :boolean, default: false

    field :deleted_at, :utc_datetime_usec

    timestamps()
  end

  def list_subscribable() do
    __MODULE__
    |> where([p], p.subscribable == true)
    |> where([p], is_nil(p.deleted_at))
  end

  def fetch(plan_id) do
    __MODULE__
    |> where([p], p.id == ^plan_id)
    |> where([p], is_nil(p.deleted_at))
  end

  def fetch_trial() do
    __MODULE__
    |> where([p], p.type == :trial)
    |> where([p], is_nil(p.deleted_at))
  end

  def month_price(%__MODULE__{billing_cycle: billing_cycle, price: price}) do
    case billing_cycle do
      :monthly -> price
      :yearly -> price |> Decimal.div(12)
    end
  end

  # 현재는 subscribable = payable = is not trial
  def check_subscribable(%__MODULE__{subscribable: true}), do: :ok
  def check_subscribable(%__MODULE__{subscribable: false}), do: {:error, :plan_not_subscribable}

  def calc_start_on(%__MODULE__{type: :trial}, origin_start_on, _extension_count = 0) do
    origin_start_on
  end

  def calc_start_on(%__MODULE__{type: type} = struct, origin_start_on, extension_count)
      when type != :trial do
    calc_end_on(struct, origin_start_on, extension_count - 1)
  end

  def calc_end_on(%__MODULE__{type: :trial}, origin_start_on, _extension_count = 0) do
    origin_start_on |> Timex.shift(days: 7)
  end

  def calc_end_on(
        %__MODULE__{type: type, billing_cycle: billing_cycle},
        origin_start_on,
        extension_count
      )
      when type != :trial do
    DateTimeHelper.calc_next(origin_start_on, billing_cycle, extension_count + 1)
  end
end
