defmodule Carrier.Core.TraversableTest do
  use ExUnit.Case, async: true
  alias Carrier.Core.Traversable

  describe "traverse/1" do
    test "with all ok tuples" do
      list = [
        {:ok, 1},
        :ok,
        {:ok, 3}
      ]

      assert list |> Traversable.traverse() == {:ok, [1, nil, 3]}
    end

    test "with ok and error tuples" do
      list = [
        {:error, 1},
        {:ok, 2},
        {:error, 3}
      ]

      assert list |> Traversable.traverse() == {:error, 1}
    end
  end
end
