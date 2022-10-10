defmodule Carrier.Core.NumberHelper do
  use Cldr,
    default_locale: :ko,
    locales: [:ko, :en],
    providers: [Cldr.Number]
end
