defmodule Carrier.Core.Cldr do
  use Cldr,
    default_locale: :ko,
    locales: [:ko, :en],
    providers: [Cldr.Number]
end
