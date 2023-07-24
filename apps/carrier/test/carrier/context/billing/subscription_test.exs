defmodule Carrier.Billing.SubscriptionTest do
  use Carrier.DataCase, async: true
  alias Carrier.Billing.Subscription
  alias Carrier.Factory

  describe "get_info_for_next_subscription/1" do
    test "with origin subscription" do
      origin_subscription = Factory.insert(:subscription, origin_subscription_id: nil)

      assert Subscription.get_info_for_next_subscription(origin_subscription) ==
               %{
                 origin_subscription_id: origin_subscription.id
               }
    end

    test "with non-origin subscription" do
      origin_subscription = Factory.insert(:subscription, origin_subscription_id: nil)

      subscription =
        Factory.insert(:subscription, origin_subscription_id: origin_subscription.id)

      assert Subscription.get_info_for_next_subscription(subscription) ==
               %{origin_subscription_id: origin_subscription.id}
    end
  end

  test "calc_unique_key/1" do
    subscription0 = Factory.insert(:subscription)
    subscription1 = Factory.insert(:subscription)

    unique_key0 = Subscription.calc_unique_key(subscription0)
    unique_key1 = Subscription.calc_unique_key(subscription0)
    unique_key2 = Subscription.calc_unique_key(subscription1)

    assert unique_key0 == unique_key1
    assert unique_key0 != unique_key2
    assert unique_key0 |> String.length() >= 8
  end
end
