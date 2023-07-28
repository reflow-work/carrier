defmodule Carrier.Integrations.ConnInfo.Redash do
  use Carrier.Integrations.ConnInfo.Info

  @primary_key false
  embedded_schema do
    field :host, :string
    field :api_key, :string
  end

  @impl true
  @required [:host, :api_key]
  def changeset(%__MODULE__{} = struct \\ %__MODULE__{}, attrs) do
    struct
    |> cast(attrs, @required)
    |> validate_required(@required)
  end
end
