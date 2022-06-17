defmodule CarrierWorkerTest do
  use ExUnit.Case
  doctest CarrierWorker

  test "greets the world" do
    assert CarrierWorker.hello() == :world
  end
end
