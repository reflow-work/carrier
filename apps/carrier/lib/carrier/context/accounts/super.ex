defmodule Carrier.Accounts.Super do
  alias Carrier.Accounts.{Org, User}
  alias Carrier.Roles.Role
  alias Carrier.Roles.Super
  alias Carrier.Repo

  def auth(email, org_id) do
    case fetch_user_by_email(email) do
      {:ok, %User{} = user} ->
        # sign in
        {:ok, {:signed_in, user}}

      _ ->
        # sign up
        Repo.wrap_transaction(fn ->
          with {:ok, {org_id, role_name}} <- ensure_org_id_role_name_for_signup(email, org_id),
               {:ok, %Role{id: role_id}} <- Super.fetch_role_by_name(role_name),
               {:ok, %User{} = user} <-
                 signup(%{org_id: org_id, email: email, role_id: role_id}) do
            {:ok, {:signed_up, user}}
          end
        end)
    end
  end

  def create_org(%{name: name}) do
    Org.create(%{name: name})
    |> Repo.insert()
  end

  def fetch_user_by_email(email) do
    User.get_by_email(email)
    |> Repo.one(org_id: :skip)
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
    |> Repo.insert()
  end

  def postload_role(%User{} = user) do
    user
    |> Repo.preload(:role, org_id: :skip)
  end

  def get_org(org_id) do
    Org.get(org_id)
    |> Repo.one(org_id: :skip)
    |> case do
      %Org{} = org -> {:ok, org}
      nil -> {:error, {:resource_not_found, %{target: Org, conditions: %{org_id: org_id}}}}
    end
  end

  defp ensure_org_id_role_name_for_signup(email, nil) do
    user_domain = String.split(email, "@") |> List.last()

    case Org.get_by_domain(user_domain) |> Repo.one(org_id: :skip) do
      %Org{org_id: org_id} ->
        {:ok, {org_id, "Member"}}

      nil ->
        {:ok, %Org{org_id: org_id}} = create_org(%{name: "organization"})
        {:ok, {org_id, "Admin"}}
    end
  end

  defp ensure_org_id_role_name_for_signup(_email, org_id) do
    {:ok, {org_id, "Member"}}
  end
end
