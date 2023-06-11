defmodule CarrierWeb.Helpers.SlackHelper do
  use CarrierWeb, :verified_routes

  def get_redirect_uri(nil) do
    url(~p"/app/data-targets/callback/slack")
  end

  def get_redirect_uri(data_target_id) do
    url(~p"/app/data-targets/callback/slack?data_target_id=#{data_target_id}")
  end
end
