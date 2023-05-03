defmodule Carrier.Role.Permission do
  def all() do
    [
      "member.access_setting",
      "member.read",
      "member.invite",
      "member.update",
      "member.delete",
      "billing.access_setting",
      "billing.subscription.read",
      "billing.subscription.manage",
      "billing.credit_card.manage"
    ]
  end
end
