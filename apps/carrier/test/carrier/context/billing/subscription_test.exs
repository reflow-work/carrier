defmodule Carrier.Billing.SubscriptionTest do
  use Carrier.DataCase, async: true
  alias Carrier.Billing.Subscription
  alias Carrier.TenantFactory

  @moduletag repo: TenantRepo

  describe "get_info_for_next_subscription/1" do
    test "with origin subscription" do
      origin_subscription = TenantFactory.insert(:subscription, origin_subscription_id: nil)

      assert Subscription.get_info_for_next_subscription(origin_subscription) ==
               %{
                 origin_subscription_id: origin_subscription.id
               }
    end

    test "with non-origin subscription" do
      origin_subscription = TenantFactory.insert(:subscription, origin_subscription_id: nil)

      subscription =
        TenantFactory.insert(:subscription, origin_subscription_id: origin_subscription.id)

      assert Subscription.get_info_for_next_subscription(subscription) ==
               %{origin_subscription_id: origin_subscription.id}
    end
  end
end
