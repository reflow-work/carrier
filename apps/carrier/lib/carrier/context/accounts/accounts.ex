defmodule Carrier.Accounts do
  alias Carrier.Accounts.{Org, User}
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
      %User{} = user -> {:ok, user}
      nil -> {:error, {:resource_not_found, %{target: User, conditions: %{user_id: user_id}}}}
    end
  end

  def update_user(user_id, attrs) do
    with {:ok, %User{} = user} <- fetch_user(user_id),
         {:ok, %User{} = updated_user} <- User.update(user, attrs) |> TenantRepo.update() do
      {:ok, updated_user}
    end
  end
end
