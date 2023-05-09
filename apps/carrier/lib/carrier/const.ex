defmodule Carrier.Const do
  @common_values %{
    terms_of_service_url: "https://reflow-work.notion.site/94ba0ee761f8453b9cc31e9cf59430df",
    privacy_policy_url: "https://reflow-work.notion.site/cca0124a9a5745f6a22f3532ae24ce91",
    refund_policy_url: "https://reflow-work.notion.site/14781220fe5b4b4b89be2db5eb7cccf4"
  }

  @env_values (case Mix.env() do
                 :prod ->
                   %{
                     report_image_storage: %{
                       region: "ap-northeast-2",
                       bucket: "carrier-chart-img"
                     }
                   }

                 _ ->
                   %{
                     report_storage: %{
                       region: "ap-northeast-2",
                       bucket: "carrier-report-test"
                     }
                   }
               end)

  @values Map.merge(@common_values, @env_values)

  def get(key) do
    %{^key => value} = @values

    value
  end
end
