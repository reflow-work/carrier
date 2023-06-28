defmodule Carrier.Role.Permission do
  def all() do
    [
      "billing.payment.manage",
      "data-source.max-count.1",
      "data-source.max-count.infinity",
      "reports.max-count.50",
      "reports.max-count.infinity"
    ]
  end
end
