defmodule Carrier.Core.AsyncTest do
  use ExUnit.Case, async: true
  alias Carrier.Core.Async

  describe "map/3" do
    test "with ok results" do
      list = [1, 2]

      assert [{:ok, 2}, {:ok, 3}] = Async.map(list, &(&1 + 1))
    end

    test "with some timeout results" do
      list = [1, 2]

      assert [{:ok, 2}, {:error, :timeout}] =
               Async.map(
                 list,
                 fn i ->
                   Process.sleep((i - 1) * 1000)
                   i + 1
                 end,
                 timeout: 1000
               )
    end
  end
end
