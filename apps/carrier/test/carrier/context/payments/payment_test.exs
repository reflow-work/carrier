defmodule Carrier.Context.Payments.PaymentTest do
  use Carrier.DataCase, async: true
  alias Carrier.Payments.Payment

  @moduletag repo: TenantRepo

  test "calc_unique_key/1" do
    payment0 = TenantFactory.insert(:payment)
    payment1 = TenantFactory.insert(:payment)

    unique_key0 = Payment.calc_unique_key(payment0)
    unique_key1 = Payment.calc_unique_key(payment0)
    unique_key2 = Payment.calc_unique_key(payment1)

    assert unique_key0 == unique_key1
    assert unique_key0 != unique_key2
    assert unique_key0 |> String.length() >= 8
  end
end
