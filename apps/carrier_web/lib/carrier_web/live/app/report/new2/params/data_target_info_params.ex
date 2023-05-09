defmodule CarrierWeb.App.ReportLive.New2.DataTargetInfoParams do
  use Ecto.Schema
  import Ecto.Changeset
  alias CarrierWeb.App.ReportLive.New2.SlackParams

  @primary_key false
  embedded_schema do
    field :data_target_id, :id
    field :target, Ecto.Enum, values: [:slack]
    field :params, :map
  end

  @required [:data_target_id, :target, :params]
  def changeset(%__MODULE__{} = struct, attrs) do
    struct
    |> cast(attrs, @required)
    |> validate_required(@required)
    |> validate_params()
  end

  defp validate_params(%Ecto.Changeset{changes: %{target: target}, valid?: true} = changeset) do
    changeset
    |> validate_change(:params, fn :params, params ->
      params_module =
        case target do
          :slack -> SlackParams
        end

      params_changeset = params_module.changeset(struct(params_module), params)

      case params_changeset.valid? do
        true -> []
        false -> params_changeset.errors
      end
    end)
  end

  defp validate_params(changeset), do: changeset
end
