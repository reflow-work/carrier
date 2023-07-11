defmodule Carrier.Pagex.Cursor do
  @enforce_keys [:order_by]
  defstruct [:next_cursor, :order_by, :size]

  def new(map) when is_map(map) do
    next_cursor = map |> Map.get(:next_cursor, nil) |> decode_cursor!()
    order_by = map |> Map.get(:order_by)
    size = map |> Map.get(:size, nil)

    %__MODULE__{next_cursor: next_cursor, order_by: order_by, size: size}
  end

  defmodule Meta do
    @enforce_keys [:next_cursor, :size, :last?]
    defstruct @enforce_keys
  end

  @behaviour Carrier.Pagex

  import Ecto.Query
  alias Carrier.Pagex
  alias Carrier.Core.Nillable

  @impl true
  def generate_query(query, %__MODULE__{next_cursor: next_cursor, order_by: order_by, size: size}) do
    query
    |> paginate_next_cursor(next_cursor, order_by)
    |> paginate_order_by(order_by)
    |> paginate_size(size)
  end

  @impl true
  def generate_result(entries, %__MODULE__{size: size} = pagination) do
    last? =
      case size do
        size when is_integer(size) -> Enum.count(entries) < size + 1
        nil -> true
      end

    entries = entries |> Nillable.run(size, &(&1 |> Enum.take(size)))

    next_cursor =
      case last? do
        true ->
          nil

        false ->
          entries
          |> List.last()
          |> Nillable.map(&(&1 |> to_encoded_cursor(pagination)))
      end

    %Pagex.Result{
      entries: entries,
      meta: %__MODULE__.Meta{next_cursor: next_cursor, size: size, last?: last?}
    }
  end

  defp paginate_next_cursor(query, next_cursor, order_by) when is_list(next_cursor) do
    {_, source_module} = query.from.source

    {_, condition_query} =
      Enum.zip(order_by, next_cursor)
      |> Enum.map(fn {{order_direction, order_key}, cursor_value} ->
        cursor_value =
          case source_module.__schema__(:type, order_key) do
            :utc_datetime_usec -> cursor_value |> DateTime.from_unix!(:microsecond)
            _ -> cursor_value
          end

        {{order_direction, order_key}, cursor_value}
      end)
      |> Enum.reduce({[], dynamic(false)}, fn comparing_condition,
                                              {equal_conditions, condition_query} ->
        new_condition_query = condition_to_query(equal_conditions, comparing_condition)

        {equal_conditions ++ [comparing_condition],
         dynamic([q], ^condition_query or ^new_condition_query)}
      end)

    query |> where(^condition_query)
  end

  defp paginate_next_cursor(query, nil, _order_by) do
    query
  end

  defp paginate_order_by(query, order_by) when is_list(order_by) do
    from(query, order_by: ^order_by)
  end

  defp paginate_order_by(query, nil) do
    query
  end

  defp paginate_size(query, size) when is_integer(size) do
    # query 1 more for checking last?
    from(query, limit: ^size + 1)
  end

  defp paginate_size(query, nil = _size) do
    query
  end

  defp condition_to_query(equal_conditions, comparing_condition) do
    equal_condition_query =
      equal_conditions
      |> Enum.reduce(dynamic(true), fn condition, condition_query ->
        dynamic(^condition_query and ^get_equal_condition_query(condition))
      end)

    comparing_condition_query = get_comparing_condition_query(comparing_condition)

    dynamic(^equal_condition_query and ^comparing_condition_query)
  end

  defp get_equal_condition_query({{_, order_key}, cursor_value}) do
    dynamic([q], field(q, ^order_key) == ^cursor_value)
  end

  defp get_comparing_condition_query({{:desc, order_key}, cursor_value}) do
    dynamic([q], field(q, ^order_key) < ^cursor_value)
  end

  defp get_comparing_condition_query({{:asc, order_key}, cursor_value}) do
    dynamic([q], field(q, ^order_key) > ^cursor_value)
  end

  def to_encoded_cursor(struct, %__MODULE__{order_by: order_by}) do
    cursor_fields = order_by |> Keyword.values()

    cursor_fields
    |> Enum.map(fn cursor_field ->
      cursor_value = struct |> Map.get(cursor_field)

      case struct.__struct__.__schema__(:type, cursor_field) do
        :utc_datetime_usec -> cursor_value |> DateTime.to_unix(:microsecond)
        _ -> cursor_value
      end
    end)
    |> encode_cursor()
  end

  defp decode_cursor!(cursor) when is_binary(cursor) do
    cursor |> Base.url_decode64!() |> Jason.decode!()
  end

  defp decode_cursor!(nil) do
    nil
  end

  defp encode_cursor(value) do
    value |> Jason.encode!() |> Base.url_encode64()
  end
end
