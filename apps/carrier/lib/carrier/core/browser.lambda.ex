defmodule Carrier.Core.Browser.Lambda do
  alias Carrier.External.Aws

  def screenshot(url) do
    Aws.create_internal_client()
    |> Aws.Lambda.invoke("carrier-shot-production-screenshot", %{"url" => url})
    |> case do
      {:ok, %{"body" => body}, _} ->
        %{"screenshotBase64" => screenshot_base64} = body |> Jason.decode!()
        screenshot_binary = screenshot_base64 |> Base.decode64!()

        {:ok, screenshot_binary}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
