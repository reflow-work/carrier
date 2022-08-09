defmodule Carrier.Accounts do
  alias Carrier.Accounts.{Org, User}
  alias Carrier.Repo

  def create_org(%{name: name}) do
    Org.create(%{name: name})
    |> Repo.insert()
  end

  def fetch_user_by_email(email) do
    User.get_by_email(email)
    |> Repo.one()
    |> case do
      %User{} = user -> {:ok, user}
      nil -> {:error, {:resource_not_found, target: User, conditions: %{email: email}}}
    end
  end

  def signup(%{org_id: org_id, email: email}) do
    User.create(%{org_id: org_id, email: email})
    |> Repo.insert()
  end
end
