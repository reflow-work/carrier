defmodule Carrier.Reports.Report do
  use Carrier.Schema

  schema "reports" do
    field :org_id, :integer
    field :name, :string
    field :trigger_time, :time

    embeds_one(:integration_info, IntegrationInfo, primary_key: false, on_replace: :delete) do
      field :integration_id, :integer
      field :channel_id, :string
    end

    embeds_one(:data_source_info, DataSourceInfo, primary_key: false, on_replace: :delete) do
      field :data_source_id, :integer
      field :sql_template, :string
      field :timezone, :string
      field :period, :integer
      field :window_size, :integer
      field :comparing_period, :integer
      field :columns, {:array, :string}
    end

    field :deleted_at, :utc_datetime_usec

    timestamps()
  end

  @required_for_create [:org_id, :name]
  defp changeset_for_create(%__MODULE__{} = struct, attrs) do
    struct
    |> cast(attrs, @required_for_create)
    |> validate_required(@required_for_create)
  end

  @required_for_delete [:deleted_at]
  defp changeset_for_delete(%__MODULE__{} = struct, attrs) do
    struct
    |> cast(attrs, @required_for_delete)
    |> validate_required(@required_for_delete)
  end

  def create(%{org_id: org_id, name: name}) do
    %__MODULE__{}
    |> changeset_for_create(%{org_id: org_id, name: name})
  end

  def list() do
    __MODULE__
    |> where([r], is_nil(r.deleted_at))
  end

  def fetch(report_id) do
    __MODULE__
    |> where([r], r.id == ^report_id)
  end

  def delete(%__MODULE__{} = struct, %DateTime{} = deleted_at) do
    struct
    |> changeset_for_delete(%{deleted_at: deleted_at})
  end
end
