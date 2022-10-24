defmodule Carrier.Core.MapHelper do
  def deep_merge(map1, map2) do
    resolver = fn func ->
      fn
        _k, v1, v2 when is_map(v1) and is_map(v2) ->
          Map.merge(v1, v2, func.(func))

        _k, _v1, v2 ->
          v2
      end
    end

    Map.merge(map1, map2, resolver.(resolver))
  end
end
