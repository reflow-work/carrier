defmodule Carrier.TenantFactory do
  use ExMachina.Ecto, repo: Carrier.TenantRepo
  use Carrier.{Accounts, Secrets, Reports, Setting, Payments, Billing}
  alias Carrier.Core.Crypto

  def org_factory() do
    %Org{
      name: seq(:org_name)
    }
  end

  def user_factory(attrs) do
    {org, attrs} = attrs |> Map.pop_lazy(:org, fn -> insert(:org) end)

    %User{
      org: org,
      email: seq(:user_email, &"user-#{&1}@email.com")
    }
    |> merge_attributes(attrs)
  end

  def integration_factory(attrs) do
    {service_name, attrs} = attrs |> Map.pop(:service_name, Enum.random([:slack]))

    {org_id, attrs} = attrs |> Map.pop_lazy(:org_id, fn -> insert(:org).org_id end)

    {conn_info_id, attrs} =
      attrs
      |> Map.pop_lazy(:conn_info_id, fn ->
        insert(:conn_info, org_id: org_id, source: service_name).id
      end)

    %Integration{
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

    {integration_id, attrs} =
      attrs |> Map.pop_lazy(:integration_id, fn -> insert(:integration, org_id: org_id).id end)

    {data_source_id, attrs} =
      attrs |> Map.pop_lazy(:data_source_id, fn -> insert(:data_source, org_id: org_id).id end)

    %Report{
      org_id: org_id,
      report_info: report_info,
      name: seq(:report_name),
      trigger_time: Time.utc_now(),
      timezone: "Asia/Seoul",
      integration_info: %{
        integration_id: integration_id,
        channel_id: "channel_id"
      },
      data_source_info: %{
        data_source_info: data_source_id,
        source: :postgres,
        sql_template: @sql_template,
        timezone: "Asia/Seoul",
        period: 28,
        window_size: 7,
        comparing_period: 7,
        columns: ["total_revenue"]
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

  def plan_factory(attrs) do
    {type, attrs} = attrs |> Map.pop(:type, Enum.random([:trial, :basic, :pro]))

    {billing_cycle, subscribable} =
      case type do
        :trial -> {:none, false}
        _ -> {attrs |> Map.get(:billing_cycle, Enum.random([:monthly, :yearly])), true}
      end

    {status, attrs} = attrs |> Map.pop(:status, :active)

    %Plan{
      billing_cycle: billing_cycle,
      name: seq(:plan_name),
      type: type,
      price: Enum.random(0..10_000_000) |> Decimal.new(),
      currency: :KRW,
      description: [seq(:plan_description), seq(:plan_description)],
      subscribable: subscribable
    }
    |> apply_status(status)
    |> merge_attributes(attrs)
  end

  def subscription_factory(attrs) do
    {org_id, attrs} = attrs |> Map.pop_lazy(:org_id, fn -> insert(:org).org_id end)
    {plan, attrs} = attrs |> Map.pop_lazy(:plan, fn -> insert(:plan, type: :basic) end)
    {start_on, attrs} = attrs |> Map.pop(:start_on, DateTime.utc_now())
    end_on = Plan.calc_end_on(plan, start_on, 0)
    {status, attrs} = attrs |> Map.pop(:status, :active)

    %Subscription{
      org_id: org_id,
      plan: plan,
      extension_count: 0,
      start_on: start_on,
      end_on: end_on
    }
    |> apply_status(status)
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

  def feature_flag_value_factory(attrs) do
    {org_id, attrs} = attrs |> Map.pop_lazy(:org_id, fn -> insert(:org).org_id end)
    {feature_flag, attrs} = attrs |> Map.pop_lazy(:feature_flag, fn -> insert(:feature_flag) end)

    %FeatureFlagValue{
      org_id: org_id,
      feature_flag: feature_flag,
      feature_flag_key: feature_flag.key,
      value: true
    }
    |> merge_attributes(attrs)
  end

  def credit_card_factory(attrs) do
    {org_id, attrs} = attrs |> Map.pop_lazy(:org_id, fn -> insert(:org).org_id end)

    %CreditCard{
      org_id: org_id,
      provider: Enum.random([:toss_payments]),
      billing_key: seq(:credit_card_billing_key),
      customer_key: org_id |> Crypto.obfuscate(),
      card_company: Enum.random(["현대"]),
      card_number: seq(:credit_card_card_number)
    }
    |> merge_attributes(attrs)
  end

  def payment_factory(attrs) do
    {org_id, attrs} = attrs |> Map.pop_lazy(:org_id, fn -> insert(:org).org_id end)

    {credit_card, attrs} =
      attrs |> Map.pop_lazy(:credit_card, fn -> insert(:credit_card, org_id: org_id) end)

    {status, attrs} = attrs |> Map.pop(:status, :confirmed)

    %Payment{
      org_id: org_id,
      credit_card: credit_card,
      amount: Decimal.new(100_000),
      currency: :KRW
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

  defp apply_status(%Plan{} = plan, :active) do
    plan
  end

  defp apply_status(%Plan{} = plan, :deleted) do
    plan
    |> apply_status(:active)
    |> Map.merge(%{deleted_at: DateTime.utc_now()})
  end

  defp apply_status(%Subscription{} = subscription, :pending) do
    subscription
  end

  defp apply_status(%Subscription{} = subscription, :active) do
    subscription
    |> apply_status(:pending)
    |> Map.merge(%{
      status: :active,
      payment: insert(:payment),
      activated_at: DateTime.utc_now()
    })
  end

  defp apply_status(%Subscription{} = subscription, :expired) do
    subscription
    |> apply_status(:active)
    |> Map.merge(%{
      status: :expired,
      expired_at: DateTime.utc_now()
    })
  end

  defp apply_status(%Payment{} = payment, :pending) do
    payment
  end

  defp apply_status(%Payment{} = payment, :confirmed) do
    payment
    |> apply_status(:pending)
    |> Map.merge(%{
      status: :confirmed,
      confirmed_at: DateTime.utc_now(),
      provider: payment.credit_card.provider,
      provider_key: seq(:payment_provider_key),
      payload: %{}
    })
  end

  defp seq(name) when is_atom(name) do
    sequence(Atom.to_string(name))
  end

  defp seq(name, formatter) do
    sequence(name, formatter)
  end
end
