defmodule Carrier.Const do
  @values %{
    refund_policy_url: "https://reflow-work.notion.site/reflow-14781220fe5b4b4b89be2db5eb7cccf4"
  }

  def get(key) do
    %{^key => value} = @values

    value
  end
end
