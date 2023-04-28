defmodule CarrierWeb.App.DataSourceLive.New.ConnInfoParams.Tableau do
  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field :org_id, :id
    field :name, :string
    field :source, Ecto.Enum, values: [:tableau], default: :tableau

    embeds_one :conn_info, ConnInfo, primary_key: false do
      field :host, :string
      field :type, Ecto.Enum, values: [:user, :pat]
      field :email, :string
      field :password, :string
      field :pat_name, :string
      field :pat_secret, :string
      field :site, :string
    end
  end

  @required [:org_id, :name]
  def changeset(%__MODULE__{} = struct \\ %__MODULE__{}, attrs) do
    struct
    |> cast(attrs, @required)
    |> validate_required(@required)
    |> cast_embed(:conn_info, with: &changeset_for_conn_info/2, required: true)
  end

  @required_for_conn_info [:host, :type, :site]
  @optional_for_conn_info [:email, :password, :pat_name, :pat_secret]
  defp changeset_for_conn_info(%__MODULE__.ConnInfo{} = struct, attrs) do
    struct
    |> cast(attrs, @required_for_conn_info ++ @optional_for_conn_info)
    |> validate_required(@required_for_conn_info)
  end

  def init_attrs() do
    %{conn_info: %{}}
  end
end
