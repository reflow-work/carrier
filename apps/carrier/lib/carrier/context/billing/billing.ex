defmodule Carrier.Billing do
  alias Carrier.Billing.Plan
  alias Carrier.Repo

  defmacro __using__([]) do
    quote do
      alias Carrier.Billing
      alias Carrier.Billing.Plan
    end
  end

  def list_subscribable_plans() do
    Plan.list_subscribable()
    |> Repo.all()
    |> then(&{:ok, &1})
  end
end
