defmodule Carrier.Data.Target do
  @callback header_to_messages(data_target :: map(), header :: map()) ::
              {:ok, list()} | {:error, any()}
  @callback threads_to_messages(data_target :: map(), threads :: list()) ::
              {:ok, list()} | {:error, any()}
  @callback send_messages(
              data_target :: map(),
              header_messages :: list(),
              messages :: list(),
              params :: map()
            ) ::
              :ok | {:error, any()}

  use Carrier.Integrations
  alias __MODULE__.Slack

  defmacro __using__([]) do
    quote do
      alias unquote(__MODULE__)
    end
  end

  def header_to_messages(%DataTarget{} = data_target, header) do
    target_module = data_target_to_module(data_target)

    target_module.header_to_messages(data_target, header)
  end

  def threads_to_messages(%DataTarget{} = data_target, blocks) do
    target_module = data_target_to_module(data_target)

    target_module.threads_to_messages(data_target, blocks)
  end

  def send_messages(%DataTarget{} = data_target, header_messages, message, params) do
    target_module = data_target_to_module(data_target)

    target_module.send_messages(data_target, header_messages, message, params)
  end

  def data_target_to_module(%DataTarget{service_name: service_name}) do
    case service_name do
      :slack -> Slack
    end
  end
end
