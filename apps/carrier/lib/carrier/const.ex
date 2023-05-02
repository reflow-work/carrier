defmodule Carrier.Const do
  @values %{
    terms_of_service_url: "https://reflow-work.notion.site/94ba0ee761f8453b9cc31e9cf59430df",
    privacy_policy_url: "https://reflow-work.notion.site/cca0124a9a5745f6a22f3532ae24ce91",
    refund_policy_url: "https://reflow-work.notion.site/14781220fe5b4b4b89be2db5eb7cccf4"
  }

  def get(key) do
    %{^key => value} = @values

    value
  end
end
