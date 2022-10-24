defmodule Carrier.Core.MapHelperTest do
  use ExUnit.Case, async: true
  alias Carrier.Core.MapHelper

  describe "deep_merge/2" do
    test "with nested map" do
      map1 = %{
        "key0" => %{
          "key00" => 0,
          "key01" => 1
        },
        "key1" => 1
      }

      map2 = %{
        "key0" => %{
          "key01" => 100,
          "key02" => 2
        },
        "key2" => %{
          "key20" => 1
        },
        "key3" => 3
      }

      assert %{
               "key0" => %{
                 "key00" => 0,
                 "key01" => 100,
                 "key02" => 2
               },
               "key1" => 1,
               "key2" => %{
                 "key20" => 1
               },
               "key3" => 3
             } == MapHelper.deep_merge(map1, map2)
    end
  end
end
