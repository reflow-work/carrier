defmodule Carrier.Billing.Plan do
  use Carrier.Schema

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
end
