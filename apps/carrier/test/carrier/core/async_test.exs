defmodule Carrier.Core.AsyncTest do
  use ExUnit.Case, async: true
  alias Carrier.Core.Async

  describe "map/3" do
    test "with ok results" do
      list = [1, 2]

      assert [{:ok, 2}, {:ok, 3}] = Async.map(list, &(&1 + 1))
    end

    test "with dictionary_keys option" do
      Process.put(:value, 2)

      list = [1, 2]

      assert [{:ok, 3}, {:ok, 4}] =
               Async.map(list, &(&1 + Process.get(:value)), dictionary_keys: [:value])
    end

    test "with some timeout results" do
      list = [1, 2]

      assert [{:ok, 2}, {:error, :timeout}] =
               Async.map(
                 list,
                 fn i ->
                   Process.sleep((i - 1) * 1500)
                   i + 1
                 end,
                 timeout: 1000
               )
    end
  end

  describe "run/2" do
    test "with valid params" do
      pid = self()

      assert {:ok, _} = Async.run(fn -> send(pid, 1) end)
      assert_receive 1
    end

    test "with dictionary_keys option" do
      Process.put(:value, 2)

      pid = self()

      assert {:ok, _} = Async.run(fn -> send(pid, Process.get(:value)) end, dictionary_keys: [:value])
      assert_receive 2
    end
  end
end
