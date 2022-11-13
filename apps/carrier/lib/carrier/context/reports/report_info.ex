defmodule Carrier.Reports.ReportInfo do
  use Carrier.Schema

  schema "report_infos" do
    field :org_id, :integer

    field :deleted_at, :utc_datetime_usec

    timestamps()
  end
end
