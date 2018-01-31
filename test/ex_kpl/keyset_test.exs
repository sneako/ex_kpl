defmodule ExKpl.KeysetTest do
  use ExUnit.Case

  alias ExKpl.Keyset

  test "empty keyset" do
    keyset = %Keyset{}
    assert [] == Keyset.key_list(keyset)
    refute Keyset.key?("foo", keyset)
    assert 0 == Keyset.potential_index("foo", keyset)
  end

  test "keyset with one key" do
    keyset = %Keyset{}
    {0, keyset} = Keyset.get_or_add_key("foo", keyset)
    assert ["foo"] == Keyset.key_list(keyset)
    assert Keyset.key?("foo", keyset)
    {0, keyset} = Keyset.get_or_add_key("foo", keyset)
    assert 1 == Keyset.potential_index("bar", keyset)
  end

  test "keyset with two keys" do
    keyset = %Keyset{}
    {0, keyset} = Keyset.get_or_add_key("foo", keyset)
    {1, keyset} = Keyset.get_or_add_key("bar", keyset)
    assert Keyset.key?("foo", keyset)
    assert Keyset.key?("bar", keyset)
    {0, keyset} = Keyset.get_or_add_key("foo", keyset)
    {1, keyset} = Keyset.get_or_add_key("bar", keyset)
    assert 2 == Keyset.potential_index("boom", keyset)
    assert ["foo", "bar"] == Keyset.key_list(keyset)
    assert 1 == Keyset.potential_index("bar", keyset)
  end
end
