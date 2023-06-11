defmodule Carrier.CommonCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      import Doumi.CaseHelper
    end
  end
end
