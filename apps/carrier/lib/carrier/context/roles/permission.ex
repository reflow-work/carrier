defmodule Carrier.Role.Permission do
  def all() do
    [
      "billing.payment.manage",
      "data-source.tableau",
      "reports.max-count.50",
      "reports.max-count.infinity"
    ]
  end
end
