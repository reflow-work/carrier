defmodule Carrier.External.Aws.Lambda do
  def invoke(client, function_name, input) do
    client |> AWS.Lambda.invoke(function_name, input)
  end
end
