defmodule Carrier.Accounts.Super do
  alias Carrier.Accounts.{Org, User}
  alias Carrier.Roles.Role
  alias Carrier.Roles.Super
  alias Carrier.TenantRepo

  def auth(email, org_id) do
    case fetch_user_by_email(email) do
      {:ok, %User{} = user} ->
        {:ok, {:signed_in, user}}

      _ ->
        case org_id do
          nil ->
            org_name = "organization"

            TenantRepo.wrap_transaction(fn ->
              with {:ok, %Org{org_id: org_id}} <- create_org(%{name: org_name}),
                   {:ok, %Role{id: role_id}} <- Super.fetch_role_by_name("Admin"),
                   {:ok, %User{} = user} <-
                     signup(%{org_id: org_id, email: email, role_id: role_id}) do
                {:ok, {:signed_up, user}}
              end
            end)

          _ ->
            TenantRepo.wrap_transaction(fn ->
              with {:ok, %Role{id: role_id}} <- Super.fetch_role_by_name("Member"),
                   {:ok, %User{} = user} <-
                     signup(%{org_id: org_id, email: email, role_id: role_id}) do
                {:ok, {:signed_up, user}}
              end
            end)
        end
    end
  end

  def create_org(%{name: name}) do
    Org.create(%{name: name})
    |> TenantRepo.insert()
  end

  def fetch_user_by_email(email) do
    User.get_by_email(email)
    |> TenantRepo.one(org_id: :skip)
    |> case do
      %User{} = user -> {:ok, user}
      nil -> {:error, {:resource_not_found, %{target: User, conditions: %{email: email}}}}
    end
  end

  def signup(%{
        org_id: org_id,
        email: email,
        role_id: role_id
      }) do
    now = DateTime.utc_now()

    User.create(%{
      org_id: org_id,
      email: email,
      signed_at: now,
      role_id: role_id
    })
    |> TenantRepo.insert()
  end

  def postload_role(%User{} = user) do
    user
    |> TenantRepo.preload(:role, org_id: :skip)
  end

  def get_org(org_id) do
    Org.get(org_id)
    |> TenantRepo.one(org_id: :skip)
    |> case do
      %Org{} = org -> {:ok, org}
      nil -> {:error, {:resource_not_found, %{target: Org, conditions: %{org_id: org_id}}}}
    end
  end
end
