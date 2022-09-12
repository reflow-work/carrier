defmodule Carrier.Accounts.User do
  use Carrier.Schema

  schema "users" do
    field :org_id, :integer
    field :email, :string
  end

  @required_for_create [:org_id, :email]
  defp changeset_for_create(%__MODULE__{} = struct, attrs) do
    struct
    |> cast(attrs, @required_for_create)
    |> validate_required(@required_for_create)
    |> unique_constraint(:email)
  end

  def create(%{org_id: org_id, email: email}) do
    %__MODULE__{}
    |> changeset_for_create(%{org_id: org_id, email: email})
  end

  def get(user_id) do
    from u in __MODULE__,
      where: u.id == ^user_id
  end

  def get_by_email(email) do
    __MODULE__
    |> where([u], u.email == ^email)
  end
end
