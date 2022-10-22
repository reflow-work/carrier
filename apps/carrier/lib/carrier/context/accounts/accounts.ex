defmodule Carrier.Accounts do
  alias Carrier.Accounts.{Org, User}
  alias Carrier.{Repo, TenantRepo}

  defmacro __using__([]) do
    quote do
      alias Carrier.Accounts
      alias Carrier.Accounts.{Org, User}
    end
  end

  def auth(email) do
    case fetch_user_by_email(email) do
      {:ok, %User{} = user} ->
        {:ok, {:signed_in, user}}

      _ ->
        org_name = "organization"

        Repo.wrap_transaction(fn ->
          with {:ok, %Org{org_id: org_id}} <- create_org(%{name: org_name}),
               {:ok, %User{} = user} <- signup(%{org_id: org_id, email: email}) do
            {:ok, {:signed_up, user}}
          end
        end)
    end
  end

  def create_org(%{name: name}) do
    Org.create(%{name: name})
    |> Repo.insert()
  end

  def fetch_user(user_id) do
    User.get(user_id)
    |> TenantRepo.one()
    |> case do
      %User{} = user -> {:ok, user}
      nil -> {:error, {:resource_not_found, %{target: User, conditions: %{user_id: user_id}}}}
    end
  end

  def fetch_user_by_email(email) do
    User.get_by_email(email)
    |> Repo.one()
    |> case do
      %User{} = user -> {:ok, user}
      nil -> {:error, {:resource_not_found, %{target: User, conditions: %{email: email}}}}
    end
  end

  def signup(%{
        org_id: org_id,
        email: email
      }) do
    now = DateTime.utc_now()

    User.create(%{
      org_id: org_id,
      email: email,
      signed_at: now,
      agreed_privacy_policy_at: now,
      agreed_terms_of_service_at: now
    })
    |> Repo.insert()
  end
end
