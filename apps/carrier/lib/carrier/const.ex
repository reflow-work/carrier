defmodule Carrier.Const do
  @common_values %{
    terms_of_service_url: "https://reflow-work.notion.site/94ba0ee761f8453b9cc31e9cf59430df",
    privacy_policy_url: "https://reflow-work.notion.site/cca0124a9a5745f6a22f3532ae24ce91",
    refund_policy_url: "https://reflow-work.notion.site/14781220fe5b4b4b89be2db5eb7cccf4",
    tableau_guide_url:
      "https://reflow-work.notion.site/Tableau-Cloud-dafbcc3df3a34ed197ff449a21059551",
    amplitude_guide_url:
      "https://reflow-work.notion.site/Amplitude-57238599ff6442538ef6757d08bb81a7",
    demo_call_url: "https://whattime.co.kr/wonny727/30min-demo-call",
    subscription_call_url: "https://whattime.co.kr/wonny727/subscribe"
  }

  @env_values (case Mix.env() do
                 :prod ->
                   %{
                     report_storage: %{
                       region: "ap-northeast-2",
                       bucket: "carrier-report-prod"
                     },
                     host_url: "https://reflow.work"
                   }

                 _ ->
                   %{
                     report_storage: %{
                       region: "ap-northeast-2",
                       bucket: "carrier-report-test"
                     },
                     host_url: "https://localhost:4001"
                   }
               end)

  @values Map.merge(@common_values, @env_values)

  def get(key) do
    %{^key => value} = @values

    value
  end
end
