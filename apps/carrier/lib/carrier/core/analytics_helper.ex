defmodule Carrier.Core.AnalyticsHelper do
  def get_page_name(uri) do
    %URI{path: path} = URI.parse(uri)

    case path do
      "/" ->
        "landing"

      "/pricing" ->
        "pricing"

      "/onboarding" ->
        "onboarding"

      "/data-sources" ->
        "data_source"

      "/data-sources/new" ->
        "data_source_new"

      "/reports" ->
        "report_list"

      "/reports/new" ->
        "report_new"

      "/report_logs" ->
        "report_log_list"

      "/settings" ->
        "setting"

      path ->
        cond do
          Regex.match?(~r/\/report\/\d+\/delete/, path) -> "report_deletion"
          Regex.match?(~r/\/report\/\d+\/edit/, path) -> "report_editing"
          true -> nil
        end
    end
  end
end
