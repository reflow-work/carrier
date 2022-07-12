defmodule Carrier.Core.DataHelperTest do
  use ExUnit.Case, async: true
  alias Carrier.Core.DataHelper

  describe "transpose/1" do
    test "with valid list" do
      assert DataHelper.transpose([[1, 5], [2, 4], [3, 3], [4, 2], [5, 1]]) == [
               [1, 2, 3, 4, 5],
               [5, 4, 3, 2, 1]
             ]
    end
  end
end
