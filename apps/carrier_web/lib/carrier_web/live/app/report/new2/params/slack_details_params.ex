defmodule CarrierWeb.App.ReportLive.New2.SlackDetailsParams do
  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field :channel_id, :string
    field :channel_name, :string
  end

  @required [:channel_id, :channel_name]
  def changeset(%__MODULE__{} = struct, attrs) do
    struct
    |> cast(attrs, @required)
  end
end
