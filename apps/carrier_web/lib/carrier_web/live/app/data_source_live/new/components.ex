defmodule CarrierWeb.App.DataSourceLive.New.Components do
  use CarrierWeb, :component
  use Carrier.Integrations

  embed_templates "*"

  attr :source, :atom, required: true
  attr :form, :any, required: true
  attr :error, :any, required: true
  attr :uploads, :any, required: true
  attr :file_name, :string, required: true
  attr :onchange, :any, required: true
  attr :onsubmit, :any, required: true

  def data_source_form(assigns)

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
