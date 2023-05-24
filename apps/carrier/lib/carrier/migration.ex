defmodule Carrier.Migration do
  defmacro __using__([]) do
    quote do
      use Ecto.Migration
      import unquote(__MODULE__)
    end
  end

  import Ecto.Migration

  def alter_nullable(table, column, nullable) do
    {execute_command, rollback_command} =
      case nullable do
        false -> {"SET", "DROP"}
        true -> {"DROP", "SET"}
      end

    execute(
      "ALTER TABLE #{table} ALTER COLUMN #{column} #{execute_command} NOT NULL",
      "ALTER TABLE #{table} ALTER COLUMN #{column} #{rollback_command} NOT NULL"
    )
  end

  def add_tstz() do
    add(:created_at, :timestamptz, null: false, default: fragment("now()"))
    add(:updated_at, :timestamptz, null: false, default: fragment("now()"))
  end
end
