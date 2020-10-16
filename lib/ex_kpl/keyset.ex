defmodule ExKpl.Keyset do
  defstruct rev_keys: [], key_to_index: %{}

  @type t :: %__MODULE__{
          # list of known keys, in reverse order
          rev_keys: [binary()],
          # map of each key to 0-based index
          key_to_index: map()
        }

  @spec key?(binary(), t()) :: boolean()
  def key?(key, %__MODULE__{key_to_index: key_to_index}), do: Map.has_key?(key_to_index, key)

  @spec get_or_add_key(nil, t()) :: {nil, t()}
  def get_or_add_key(nil, keyset), do: {nil, keyset}

  @spec get_or_add_key(binary(), t()) :: {non_neg_integer(), t()}
  def get_or_add_key(key, %__MODULE__{rev_keys: rev_keys, key_to_index: key_to_index} = keyset) do
    case Map.get(key_to_index, key, :not_found) do
      :not_found ->
        index = length(rev_keys)

        new_key_set = %__MODULE__{
          rev_keys: [key | rev_keys],
          key_to_index: Map.put(key_to_index, key, index)
        }

        {index, new_key_set}

      index ->
        {index, keyset}
    end
  end

  @spec key_list(t()) :: [binary()]
  def key_list(%__MODULE__{rev_keys: rev_keys}), do: Enum.reverse(rev_keys)

  @spec potential_index(binary(), t()) :: non_neg_integer()
  def potential_index(key, %__MODULE__{rev_keys: rev_keys, key_to_index: key_to_index}) do
    case Map.get(key_to_index, key, :not_found) do
      :not_found -> length(rev_keys)
      index -> index
    end
  end
end
