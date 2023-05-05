defmodule CarrierWeb.App.ReportLive.New2.DataTargetInfoParams do
  use Ecto.Schema
  import Ecto.Changeset
  alias CarrierWeb.App.ReportLive.New2.SlackDetailsParams

  @primary_key false
  embedded_schema do
    field :data_target_id, :id
    field :target, Ecto.Enum, values: [:slack]
    field :details, :map
  end

  @required [:data_target_id, :target, :details]
  def changeset(%__MODULE__{} = struct, attrs) do
    struct
    |> cast(attrs, @required)
    |> validate_required(@required)
    |> validate_details()
  end

  defp validate_details(%Ecto.Changeset{changes: %{target: target}, valid?: true} = changeset) do
    changeset
    |> validate_change(:details, fn :details, details ->
      details_module =
        case target do
          :slack -> SlackDetailsParams
        end

      details_changeset = details_module.changeset(struct(details_module), details)

      case details_changeset.valid? do
        true -> []
        false -> details_changeset.errors
      end
    end)
  end

  defp validate_details(changeset), do: changeset
end
