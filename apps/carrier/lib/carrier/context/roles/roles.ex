defmodule Carrier.Roles do
  defmacro __using__([]) do
    quote do
      alias Carrier.Roles

      alias Carrier.Roles.{
        Permission,
        Role
      }
    end
  end
end
