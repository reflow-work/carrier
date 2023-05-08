defmodule Carrier.Data.Target do
  @callback blocks_to_report_message(data_target :: map(), blocks :: list()) ::
              {:ok, map() | list()}
  @callback send_report_message(data_target :: map(), report_message :: map() | list()) ::
              {:ok, any()}

  use Carrier.Integrations

  defmacro __using__([]) do
    quote do
      alias unquote(__MODULE__)
    end
  end

  def blocks_to_report_message(%DataTarget{} = _data_target, blocks) do
    report_message =
      blocks
      |> Enum.map(& &1)

    {:ok, report_message}
  end

  def send_report_message(%DataTarget{} = _data_target, _report_message) do
    {:ok, nil}
  end
end
