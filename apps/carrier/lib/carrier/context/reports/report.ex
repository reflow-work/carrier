defmodule Carrier.Reports.Report do
  use Carrier.Schema

  schema "reports" do
    field :org_id, :integer
    field :name, :string

    timestamps()
  end
end
