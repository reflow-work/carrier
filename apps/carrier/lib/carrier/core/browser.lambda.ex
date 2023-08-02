defmodule Carrier.Core.Browser.Lambda do
  alias Carrier.External.Aws

  def screenshot(url) do
    Aws.create_internal_client()
    |> Aws.Lambda.invoke("carrier-shot-production-screenshot", %{"url" => url})
    |> IO.inspect()
    |> case do
      {:ok, %{"body" => body}, _} ->
        %{"screenshotBase64" => screenshot_base64} = body |> Jason.decode!()

        {:ok, screenshot_base64}
      {:error, reason} ->
        {:error, reason}
    end
  end
end
