defmodule Carrier.Data.Source.TableauDemo do
  @behaviour Carrier.Data.Source

  @impl true
  def validate_conn(:tableau_demo, _credentials, _opts) do
    :ok
  end
end
