defmodule Carrier.Integrations.ConnInfo.Tableau do
  use Carrier.Integrations.ConnInfo.Info

  @primary_key false
  embedded_schema do
    field :host, :string
    field :type, Ecto.Enum, values: [:user, :pat]
    field :email, :string
    field :password, :string
    field :pat_name, :string
    field :pat_secret, :string
    field :site, :string
  end

  @impl true
  @required [:host, :type, :site]
  @optional [:email, :password, :pat_name, :pat_secret]
  def changeset(%__MODULE__{} = struct \\ %__MODULE__{}, attrs) do
    struct
    |> cast(attrs, @required ++ @optional)
    |> validate_required(@required)
    |> validate_by_type()
  end

  defp validate_by_type(%Ecto.Changeset{changes: %{type: type}, valid?: true} = changeset) do
    case type do
      :user ->
        validate_required(changeset, [:email, :password])

      :pat ->
        validate_required(changeset, [:pat_name, :pat_secret])
    end
  end

  defp validate_by_type(%Ecto.Changeset{} = changeset) do
    changeset
  end
end
