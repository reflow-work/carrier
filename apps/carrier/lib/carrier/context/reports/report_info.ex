defmodule Carrier.Reports.ReportInfo do
  use Carrier.Schema

  schema "report_infos" do
    field :org_id, :integer

    field :deleted_at, :utc_datetime_usec

    timestamps()
  end

  @required_for_create [:org_id]
  defp changeset_for_create(%__MODULE__{} = struct, attrs) do
    struct
    |> cast(attrs, @required_for_create)
    |> validate_required(@required_for_create)
  end

  def create(%{org_id: org_id}) do
    %__MODULE__{}
    |> changeset_for_create(%{org_id: org_id})
  end
end
