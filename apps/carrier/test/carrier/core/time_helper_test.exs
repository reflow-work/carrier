defmodule Carrier.Core.TimeHelperTest do
  use ExUnit.Case, async: true
  alias Carrier.Core.TimeHelper

  describe "from!/1" do
    test "with full params" do
      assert TimeHelper.from!(hour: 1, minute: 23, second: 45) == ~T[01:23:45]
    end
  end
end
