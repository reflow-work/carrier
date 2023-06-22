defmodule Carrier.Integrations.ConnInfo.Demo do
  use Carrier.Integrations.ConnInfo.Info

  @primary_key false
  embedded_schema do
  end

  @impl true
  @required []
  def changeset(%__MODULE__{} = struct \\ %__MODULE__{}, attrs) do
    struct
    |> cast(attrs, @required)
    |> validate_required(@required)
  end
end
