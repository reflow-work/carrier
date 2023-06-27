defmodule Carrier.Core.AnalyticsHelper do
  def get_page_name(uri) do
    %URI{path: path} = URI.parse(uri)

    case path do
      "/" ->
        "landing"

      "/pricing" ->
        "pricing"

      "/app/onboarding" ->
        "onboarding"

      "/app/data-sources" ->
        "data_source"

      "/app/data-sources/new" ->
        "data_source_new"

      "/app/reports" ->
        "report_list"

      "/app/reports/new" ->
        "report_new"

      "/app/report_logs" ->
        "report_log_list"

      "/app/settings" ->
        "setting"

      "/app/reports/new2" ->
        "report_new"

      "/app/subscriptions/new" ->
        "subscription_new"

      path ->
        cond do
          Regex.match?(~r/\/app\/reports\/\w+\/delete/, path) -> "report_deletion"
          Regex.match?(~r/\/app\/reports\/\w+\/edit2/, path) -> "report_editing"
          true -> nil
        end
    end
  end
end
