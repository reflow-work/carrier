defmodule CarrierWeb.Cldr do
  use Cldr,
    default_locale: :ko,
    locales: [:ko, :en],
    providers: [Cldr.Number, Cldr.Calendar, Cldr.DateTime]
end
