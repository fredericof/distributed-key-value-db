defmodule KV.RegistryTest do
  use ExUnit.Case, async: true

  setup do
    registry = start_supervised!(KV.Registry)
    %{registry: registry}
  end

  test "spawns buckets", %{registry: registry} do
    assert KV.Client.lookup(registry, "shopping") == :error

    KV.Client.create(registry, "shopping")
    assert {:ok, bucket} = KV.Client.lookup(registry, "shopping")

    KV.Bucket.put(bucket, "milk", 1)
    assert KV.Bucket.get(bucket, "milk") == 1
  end

  test "removes buckets on exit", %{registry: registry} do
    KV.Client.create(registry, "shopping")
    {:ok, bucket} = KV.Client.lookup(registry, "shopping")
    Agent.stop(bucket)
    assert KV.Client.lookup(registry, "shopping") == :error
  end

  test "removes bucket on crash", %{registry: registry} do
    KV.Client.create(registry, "shopping")
    {:ok, bucket} = KV.Client.lookup(registry, "shopping")

    # Put a item and check
    KV.Bucket.put(bucket, "eggs", 6)
    assert KV.Bucket.get(bucket, "eggs") == 6

    # Stop the bucket with non-normal reason
    Agent.stop(bucket, :shutdown)
    assert KV.Client.lookup(registry, "shopping") == :error
  end

  test "are temporary workers" do
    assert Supervisor.child_spec(KV.Bucket, []).restart == :temporary
  end
end
