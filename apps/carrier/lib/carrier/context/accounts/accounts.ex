defmodule Carrier.Accounts do
  alias Carrier.Accounts.{Org, User, Super}
  alias Carrier.Roles.Super, as: RolesSuper
  alias Carrier.TenantRepo

  defmacro __using__([]) do
    quote do
      alias Carrier.Accounts
      alias Carrier.Accounts.{Org, User}
    end
  end

  def fetch_org() do
    Org
    |> TenantRepo.one()
    |> case do
      %Org{} = org -> {:ok, org}
      nil -> {:error, {:resource_not_found, %{target: Org}}}
    end
  end

  def update_org(attrs) do
    with {:ok, %Org{} = org} <- fetch_org(),
         {:ok, %Org{} = updated_org} <- Org.update(org, attrs) |> TenantRepo.update() do
      {:ok, updated_org}
    end
  end

  def fetch_user(user_id) do
    User.get(user_id)
    |> User.preload_org()
    |> TenantRepo.one()
    |> case do
      %User{} = user ->
        user_with_role = user |> Super.postload_role()
        {:ok, user_with_role}

      nil ->
        {:error, {:resource_not_found, %{target: User, conditions: %{user_id: user_id}}}}
    end
  end

  # TODO: it should returns billing user account
  # Assumption: There is only one admin user per Org, and that admin user bills.
  def fetch_billing_user() do
    {:ok, admin_role} = RolesSuper.fetch_role_by_name("Admin")

    User.fetch_billing(admin_role.id)
    |> User.preload_org()
    |> TenantRepo.one()
    |> case do
      %User{} = user -> {:ok, user}
      nil -> {:error, {:resource_not_found, %{target: User, conditions: %{role: :billing}}}}
    end
  end

  def update_user(user_id, attrs) do
    with {:ok, %User{} = user} <- fetch_user(user_id),
         {:ok, %User{} = updated_user} <- User.update(user, attrs) |> TenantRepo.update() do
      {:ok, updated_user}
    end
  end
end
