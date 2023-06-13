defmodule CarrierWeb.Components.DataSourceNew.Components do
  use CarrierWeb, :component
  use Carrier.Integrations

  embed_templates "*"

  attr :source, :atom, required: true
  attr :form, :any, required: true
  attr :uploads, :any, required: true
  attr :file_name, :string, required: true

  def source_inputs(assigns) do
    case assigns.source do
      :postgres -> postgres_inputs(assigns)
      :mysql -> mysql_inputs(assigns)
      :bigquery -> bigquery_inputs(assigns)
      :athena -> athena_inputs(assigns)
      :tableau -> tableau_inputs(assigns)
    end
  end
end
