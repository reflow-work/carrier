defmodule Carrier.Accounts.Super do
  alias Carrier.Accounts.{Org, User}
  alias Carrier.TenantRepo

  def auth(email) do
    case fetch_user_by_email(email) do
      {:ok, %User{} = user} ->
        {:ok, {:signed_in, user}}

      _ ->
        org_name = "organization"

        TenantRepo.wrap_transaction(fn ->
          with {:ok, %Org{org_id: org_id}} <- create_org(%{name: org_name}),
               {:ok, %User{} = user} <- signup(%{org_id: org_id, email: email}) do
            {:ok, {:signed_up, user}}
          end
        end)
    end
  end

  def create_org(%{name: name}) do
    Org.create(%{name: name})
    |> TenantRepo.insert()
  end

  def fetch_user_by_email(email) do
    User.get_by_email(email)
    |> TenantRepo.one(skip_org_id: true)
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
      signed_at: now
    })
    |> TenantRepo.insert()
  end
end
