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

  def deep_map(map, mapper) when is_map(map) and is_function(mapper, 1) do
    resolver = fn func ->
      fn
        {k, v} when is_map(v) and not is_struct(v) ->
          mapper.({k, v |> Enum.map(func.(func)) |> Map.new()})

        {k, v} ->
          mapper.({k, v})
      end
    end

    map
    |> Enum.map(resolver.(resolver))
    |> Map.new()
  end
end
