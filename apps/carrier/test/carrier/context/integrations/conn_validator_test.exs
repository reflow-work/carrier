defmodule Carrier.Integrations.ConnValidatorTest do
  use ExUnit.Case, async: true
  alias Carrier.Integrations.ConnValidator

  describe "validate/2 (postgres)" do
    @opts [max_restarts: 0, queue_interval: 100]

    setup do
      info = %{
        hostname: "localhost",
        port: 48141,
        username: "customer",
        password: "password",
        database: "customer_db",
        ssl: false
      }

      %{info: info}
    end

    test "postgres valid", %{info: info} do
      assert :ok = ConnValidator.validate(:postgres, info, :source, @opts)
    end

    test "postgres invalid info", %{info: info} do
      assert {:error, {:invalid_conn_info, _}} =
               ConnValidator.validate(:postgres, %{info | port: 48000}, :source, @opts)
    end

    test "postgres invalid credentials", %{info: info} do
      assert {:error, {:invalid_conn_info, _}} =
               ConnValidator.validate(
                 :postgres,
                 %{info | password: "invalid password"},
                 :source,
                 @opts
               )
    end
  end

  describe "validate/2 (mysql)" do
    @opts [max_restarts: 0, queue_interval: 100]

    setup do
      info = %{
        hostname: "localhost",
        port: 48142,
        username: "root",
        password: "password",
        database: "customer_db",
        ssl: false
      }

      %{info: info}
    end

    test "mysql valid", %{info: info} do
      assert :ok = ConnValidator.validate(:mysql, info, :source, @opts)
    end

    test "mysql invalid info", %{info: info} do
      assert {:error, {:invalid_conn_info, _}} =
               ConnValidator.validate(:mysql, %{info | port: 48000}, :source, @opts)
    end

    test "mysql invalid credentials", %{info: info} do
      assert {:error, {:invalid_conn_info, _}} =
               ConnValidator.validate(
                 :mysql,
                 %{info | password: "invalid password"},
                 :source,
                 @opts
               )
    end
  end
end
