defmodule Carrier.Factory do
  use ExMachina.Ecto, repo: Carrier.Repo
  use Carrier.{Accounts, Integrations, Reports, Setting, Billing}

  def org_factory() do
    %Org{
      name: seq(:org_name)
    }
  end

  def user_factory(attrs) do
    {org, attrs} = attrs |> Map.pop_lazy(:org, fn -> insert(:org) end)

    %User{
      org_id: org.org_id,
      email: seq(:user_email, &"user-#{&1}@email.com")
    }
    |> merge_attributes(attrs)
  end

  def data_target_factory(attrs) do
    {service_name, attrs} = attrs |> Map.pop(:service_name, Enum.random([:slack]))

    {org_id, attrs} = attrs |> Map.pop_lazy(:org_id, fn -> insert(:org).org_id end)

    {conn_info_id, attrs} =
      attrs
      |> Map.pop_lazy(:conn_info_id, fn ->
        insert(:conn_info, org_id: org_id, source: service_name).id
      end)

    %DataTarget{
      org_id: org_id,
      service_name: Enum.random([:slack]),
      conn_info_id: conn_info_id
    }
    |> merge_attributes(attrs)
  end

  def data_source_factory(attrs) do
    {source, attrs} = attrs |> Map.pop(:source, Enum.random([:postgres, :mysql]))

    {org_id, attrs} = attrs |> Map.pop_lazy(:org_id, fn -> insert(:org).org_id end)

    {conn_info, attrs} =
      attrs
      |> Map.pop_lazy(:conn_info, fn ->
        insert(:conn_info, org_id: org_id, source: source)
      end)

    %DataSource{
      org_id: org_id,
      name: seq(:data_source_name),
      source: source,
      conn_info: conn_info
    }
    |> merge_attributes(attrs)
  end

  def conn_info_factory(attrs) do
    {org_id, attrs} = attrs |> Map.pop_lazy(:org_id, fn -> insert(:org).org_id end)

    %ConnInfo{
      org_id: org_id,
      name: seq(:conn_info_name),
      source: [:postgres, :mysql] |> Enum.random(),
      info: %{}
    }
    |> merge_attributes(attrs)
  end

  def report_info_factory(attrs) do
    {org_id, attrs} = attrs |> Map.pop_lazy(:org_id, fn -> insert(:org).org_id end)

    %ReportInfo{
      org_id: org_id
    }
    |> merge_attributes(attrs)
  end

  @sql_template """
  SELECT DATE(order_date) as date, SUM(amount) AS total_amount, SUM(revenue) AS total_revenue
    FROM sample_data_simple
    WHERE DATE(order_date) >= {{start}} AND DATE(order_date) < {{end}}
    GROUP BY order_date
    ORDER BY order_date
  """

  def report_factory(attrs) do
    {org_id, attrs} = attrs |> Map.pop_lazy(:org_id, fn -> insert(:org).org_id end)

    {report_info, attrs} =
      attrs |> Map.pop_lazy(:report_info, fn -> insert(:report_info, org_id: org_id) end)

    {data_target_id, attrs} =
      attrs |> Map.pop_lazy(:data_target_id, fn -> insert(:data_target, org_id: org_id).id end)

    {data_source_id, attrs} =
      attrs |> Map.pop_lazy(:data_source_id, fn -> insert(:data_source, org_id: org_id).id end)

    %Report{
      org_id: org_id,
      report_info: report_info,
      name: seq(:report_name),
      trigger_time: Time.utc_now(),
      timezone: "Asia/Seoul",
      data_target_info: %{
        "data_target_id" => data_target_id,
        "channel_id" => "channel_id"
      },
      data_source_info: %{
        "data_source_info" => data_source_id,
        "sql_template" => @sql_template,
        "timezone" => "Asia/Seoul",
        "period" => 28,
        "window_size" => 7,
        "comparing_period" => 7,
        "columns" => ["total_revenue"]
      }
    }
    |> merge_attributes(attrs)
  end

  def report_log_factory(attrs) do
    {org_id, attrs} = attrs |> Map.pop_lazy(:org_id, fn -> insert(:org).org_id end)
    {report, attrs} = attrs |> Map.pop_lazy(:report, fn -> insert(:report, org_id: org_id) end)
    {status, attrs} = attrs |> Map.pop(:status, :scheduled)

    %ReportLog{
      org_id: report.org_id,
      report_info: report.report_info,
      report: report,
      report_job_id: seq(:report_log_report_job_id, & &1),
      created_at: DateTime.utc_now()
    }
    |> apply_status(status)
    |> merge_attributes(attrs)
  end

  defp apply_status(%ReportLog{} = report_log, :scheduled) do
    report_log
    |> Map.merge(%{status: :scheduled, scheduled_at: DateTime.utc_now()})
  end

  defp apply_status(%ReportLog{} = report_log, :tried) do
    report_log
    |> apply_status(:scheduled)
    |> Map.merge(%{status: :tried, tried_at: DateTime.utc_now()})
  end

  defp apply_status(%ReportLog{} = report_log, :succeeded) do
    report_log
    |> apply_status(:tried)
    |> Map.merge(%{
      status: :succeeded,
      payload: [%{"key" => "value"}],
      succeeded_at: DateTime.utc_now()
    })
  end

  def plan_factory(attrs) do
    type = attrs |> Map.get(:type, Enum.random([:trial, :paid]))

    billing_cycle =
      case type do
        :trial -> :none
        :paid -> Enum.random([:monthly, :yearly])
      end

    subscribable =
      case billing_cycle do
        :trial -> false
        :paid -> true
      end

    %Plan{
      billing_cycle: billing_cycle,
      name: seq(:plan_name),
      type: type,
      price: Enum.random(0..10_000_000) |> Decimal.new(),
      currency: :KRW,
      description: [seq(:plan_description), seq(:plan_description)],
      subscribable: subscribable
    }
    |> merge_attributes(attrs)
  end

  def property_factory() do
    %Property{
      key: sequence(:property_key, &"key-#{&1}")
    }
  end

  def feature_flag_factory(attrs) do
    %FeatureFlag{
      key: seq(:feature_flag_key),
      description: seq(:feature_flag_description)
    }
    |> merge_attributes(attrs)
  end

  defp seq(name) when is_atom(name) do
    sequence(Atom.to_string(name))
  end

  defp seq(name, formatter) do
    sequence(name, formatter)
  end
end
