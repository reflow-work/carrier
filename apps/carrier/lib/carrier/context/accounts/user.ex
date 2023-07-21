defmodule Carrier.Accounts.User do
  use Carrier.Schema
  alias Carrier.Accounts.Org
  alias Carrier.Roles.Role

  @derive Carrier.Obfuscatable.Protocol

  schema "users" do
    belongs_to :org, Org, references: :org_id
    belongs_to :role, Role

    field :email, :string
    field :position, :string

    field :signed_at, :utc_datetime_usec
    field :deleted_at, :utc_datetime_usec

    field :agreed_privacy_policy_at, :utc_datetime_usec
    field :agreed_terms_of_service_at, :utc_datetime_usec
  end

  @required_for_create [
    :org_id,
    :email,
    :signed_at,
    :role_id
  ]
  defp changeset_for_create(%__MODULE__{} = struct, attrs) do
    struct
    |> cast(attrs, @required_for_create)
    |> validate_required(@required_for_create)
    |> unique_constraint(:email)
  end

  @required_for_update [
    :position,
    :agreed_privacy_policy_at,
    :agreed_terms_of_service_at
  ]
  defp changeset_for_update(%__MODULE__{} = struct, attrs) do
    struct
    |> cast(attrs, @required_for_update)
    |> validate_required(@required_for_update)
  end

  def create(%{
        org_id: org_id,
        email: email,
        signed_at: signed_at,
        role_id: role_id
      }) do
    %__MODULE__{}
    |> changeset_for_create(%{
      org_id: org_id,
      email: email,
      signed_at: signed_at,
      role_id: role_id
    })
  end

  def get(user_id) do
    __MODULE__
    |> where([u], u.id == ^user_id)
    |> where_not_deleted()
  end

  def get_by_email(email) do
    __MODULE__
    |> where([u], u.email == ^email)
    |> where_not_deleted()
  end

  # TODO: it should returns billing user account
  def fetch_billing(admin_role_id) do
    __MODULE__
    |> where([u], u.role_id == ^admin_role_id)
    |> where_not_deleted()
  end

  def update(%__MODULE__{} = struct, attrs \\ %{}) do
    struct
    |> changeset_for_update(attrs)
  end

  def preload_org(query) do
    query |> preload([:org])
  end

  def positions do
    [
      "CEO/대표",
      "고위 경영진",
      "PO/매니저",
      "비즈니스 전문가/분석가",
      "소프트웨어 엔지니어",
      "데이터 엔지니어",
      "데이터 분석가/데이터 사이언티스트",
      "마케터",
      "컨설턴트"
    ]
  end

  def list() do
    __MODULE__
    |> where_not_deleted()
  end
end
