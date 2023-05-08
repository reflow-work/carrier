defmodule Carrier.Data do
  use Carrier.Integrations

  def load_raw_data(%DataSource{} = _data_source, _opts) do
    {:ok, []}
  end

  def transform_data(%DataSource{} = _data_source, raw_data) do
    data =
      raw_data
      |> Enum.map(& &1)

    {:ok, data}
  end

  def data_to_blocks(%DataSource{} = _data_source, data) do
    blocks =
      data
      |> Enum.map(& &1)

    {:ok, blocks}
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
