defmodule Carrier.Data.Target do
  @callback threads_to_report_messages(data_target :: map(), threads :: list()) :: {:ok, list()}
  @callback send_report_message(data_target :: map(), report_message :: map() | list()) ::
              {:ok, any()}

  use Carrier.Integrations
  alias __MODULE__.Slack

  defmacro __using__([]) do
    quote do
      alias unquote(__MODULE__)
    end
  end

  def threads_to_report_messages(%DataTarget{} = data_target, blocks) do
    target_module = data_target_to_module(data_target)

    target_module.threads_to_report_messages(data_target, blocks)
  end

  def send_report_message(%DataTarget{} = _data_target, _report_message) do
    {:ok, nil}
  end

  def data_target_to_module(%DataTarget{service_name: service_name}) do
    case service_name do
      :slack -> Slack
    end
  end
end
