defmodule CarrierWeb.Layouts do
  use CarrierWeb, :html
  import CarrierWeb.Components.Flash
  alias Carrier.Billing.Subscription

  embed_templates "layouts/*"
end
