defmodule CarrierWeb.Layouts do
  use CarrierWeb, :html
  import CarrierWeb.Components.Flash

  embed_templates "layouts/*"
end
