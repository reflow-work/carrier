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

  @required [:org_id, :provider, :billing_key, :customer_key, :card_company, :card_number]
  defp changeset_for_create(%__MODULE__{} = struct, attrs) do
    struct
    |> cast(attrs, @required)
    |> validate_required(@required)
    |> unique_constraint(:org_id)
  end

  def create(attrs) do
    %__MODULE__{}
    |> changeset_for_create(attrs)
  end

  def fetch_default() do
    __MODULE__
    |> where([cc], is_nil(cc.deleted_at))
  end

  def format_card_info(%__MODULE__{card_company: card_company, card_number: card_number}) do
    "#{card_company}, **** #{card_number |> String.slice(-4..-1)}"
  end
end
