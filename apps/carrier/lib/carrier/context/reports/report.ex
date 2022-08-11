defmodule Carrier.Reports.Report do
  use Carrier.Schema

  schema "reports" do
    field :org_id, :integer
    field :name, :string

    timestamps()
  end

  def list() do
    __MODULE__
  end
end
