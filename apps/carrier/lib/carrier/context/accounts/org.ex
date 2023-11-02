defmodule Carrier.Accounts.Org do
  use Carrier.Schema

  @derive {Carrier.Obfuscatable.Protocol, key: :org_id}

  @primary_key {:org_id, :id, autogenerate: true}
  schema "orgs" do
    field :name, :string
    field :industry, :string
    field :employee_count, :string
    field :onboarded, :boolean
    field :domain, :string

    field :deleted_at, :utc_datetime_usec
  end

  @required_for_create [:name]
  defp changeset_for_create(%__MODULE__{} = struct, attrs) do
    struct
    |> cast(attrs, @required_for_create)
  end

  @required_for_update [
    :name,
    :industry,
    :employee_count,
    :onboarded
  ]
  defp changeset_for_update(%__MODULE__{} = struct, attrs) do
    struct
    |> cast(attrs, @required_for_update)
    |> validate_required(@required_for_update)
  end

  def create(%{name: name}) do
    %__MODULE__{}
    |> changeset_for_create(%{name: name})
  end

  def update(%__MODULE__{} = struct, attrs) do
    struct
    |> changeset_for_update(attrs |> Map.put(:onboarded, true))
  end

  def get(org_id) do
    __MODULE__
    |> where([u], u.org_id == ^org_id)
    |> where_not_deleted()
  end

  def get_by_domain(domain) do
    __MODULE__
    |> where([u], u.domain == ^domain)
    |> where_not_deleted()
  end

  def industries do
    [
      "IT 서비스",
      "온라인 교육",
      "B2B",
      "쇼핑몰",
      "오프라인 기반 (병원, 학원, 숙박 등)",
      "기타 (비영리, 제조업 등)"
    ]
  end

  def employee_counts do
    [
      "1~4명",
      "5~9명",
      "10~19명",
      "20~49명",
      "50~99명",
      "100~299명",
      "300명 이상"
    ]
  end
end
