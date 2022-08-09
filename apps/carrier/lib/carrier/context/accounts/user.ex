defmodule Carrier.Accounts.User do
  use Carrier.Schema

  schema "users" do
    field :org_id, :integer
    field :email, :string
  end

  def get_by_email(email) do
    __MODULE__
    |> where([u], u.email == ^email)
  end
end
