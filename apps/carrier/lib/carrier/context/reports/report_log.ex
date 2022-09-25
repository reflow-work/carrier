defmodule Carrier.Reports.ReportLog do
  use Carrier.Schema

  schema "report_logs" do
    field :org_id, :integer
    field :report_id, :integer
    field :payload, :map
    field :tried_at, :utc_datetime_usec
    field :sent_at, :utc_datetime_usec
    field :error_message, :string

    embeds_one(:integration_info, IntegrationInfo, primary_key: false, on_replace: :delete) do
      @derive Jason.Encoder
      field :integration_id, :integer
      field :channel_id, :string
      field :channel_name, :string
    end

    embeds_one(:data_source_info, DataSourceInfo, primary_key: false, on_replace: :delete) do
      @derive Jason.Encoder
      field :data_source_id, :integer
      field :sql_template, :string
      field :timezone, :string
      field :period, :integer
      field :window_size, :integer
      field :comparing_period, :integer
      field :columns, {:array, :string}
    end
  end
end
