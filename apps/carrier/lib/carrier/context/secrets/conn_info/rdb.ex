defmodule Carrier.Secrets.ConnInfo.RDB do
  import Ecto.Changeset, only: [put_change: 3]

  def set_ssl(%Ecto.Changeset{valid?: true, changes: %{hostname: hostname}} = changeset) do
    changeset
    |> put_change(:ssl, get_ssl_option_by_hostname(hostname))
  end

  def set_ssl(changeset), do: changeset

  defp get_ssl_option_by_hostname("localhost"), do: false
  defp get_ssl_option_by_hostname("127.0.0.1"), do: false
  defp get_ssl_option_by_hostname(_), do: true
end
