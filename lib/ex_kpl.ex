defmodule ExKpl do
  @moduledoc """
  Elixir implementation of the Kinesis Producer Library record aggregator.

  This is a port of the Erlang implementation included in [adroll/erlmld](https://github.com/AdRoll/erlmld)

  ## Basic usage:

      iex> {_, aggregator} = ExKpl.add(ExKpl.new(), {"partition_key", "data"})
      ...> ExKpl.finish(aggregator)
      {{"partition_key", <<243, 137, 154, 194, 10, 13, 112, 97, 114, 116, 105, 116, 105, 111, 110, 95, 107, 101, 121, 26, 8, 8, 0, 26, 4, 100, 97, 116, 97, 208, 54, 153, 218, 90, 34, 47, 163, 33, 8, 173, 27, 217, 85, 161, 78>>, nil}, %ExKpl{agg_explicit_hash_key: nil, agg_partition_key: nil, agg_size_bytes: 0, explicit_hash_keyset: %ExKpl.Keyset{key_to_index: %{}, rev_keys: []}, num_user_records: 0, partition_keyset: %ExKpl.Keyset{key_to_index: %{}, rev_keys: []}, rev_records: []}}

  Typically you will use it like:

      case ExKpl.add(aggregator, {partition_key, data}) do
        {nil, aggregator} ->
          aggregator

        {full_record, aggregator} ->
          send_record_to_kinesis(full_record)
          aggregator
      end

  You can force the current records to be aggregated with `finish/1,2`
  """

  use Bitwise

  alias ExKpl.{Proto, Keyset}

  require Logger

  @type key :: binary() | nil
  @type raw_data :: binary()
  @type serialized_data :: binary()
  @type user_record :: {key(), raw_data(), key()}
  @type aggregated_record :: {key(), serialized_data(), key()}
  @type new_opts :: [{:max_bytes_per_record, pos_integer()}]

  @magic <<243, 137, 154, 194>>
  @magic_deflated <<244, 137, 154, 194>>
  @max_bytes_per_record bsl(1, 20)
  @md5_digest_bytes 16
  @empty_record_size %Proto.AggregatedRecord{}
                     |> Protox.encode!()
                     |> elem(1)

  defstruct num_user_records: 0,
            agg_size_bytes: 0,
            agg_partition_key: nil,
            agg_explicit_hash_key: nil,
            partition_keyset: %Keyset{},
            explicit_hash_keyset: %Keyset{},
            rev_records: [],
            max_bytes_per_record: @max_bytes_per_record

  @type t :: %__MODULE__{
          num_user_records: non_neg_integer(),
          agg_size_bytes: non_neg_integer(),
          agg_partition_key: key(),
          agg_explicit_hash_key: key(),
          partition_keyset: Keyset.t(),
          explicit_hash_keyset: Keyset.t(),
          rev_records: [binary()],
          max_bytes_per_record: pos_integer()
        }

  @spec new(new_opts()) :: t()
  def new(opts \\ []) do
    max = Keyword.get(opts, :max_bytes_per_record, @max_bytes_per_record)

    %__MODULE__{
      max_bytes_per_record: min(max, @max_bytes_per_record)
    }
  end

  @spec count(t()) :: non_neg_integer()
  def count(%__MODULE__{num_user_records: count}), do: count

  @spec size_bytes(t()) :: non_neg_integer()
  def size_bytes(%__MODULE__{agg_size_bytes: size, agg_partition_key: pk}) do
    byte_size(@magic) + size + pk_size(pk) + @md5_digest_bytes + @empty_record_size
  end

  @spec finish(t()) :: {aggregated_record() | nil, t()}
  def finish(%__MODULE__{num_user_records: 0} = agg, _), do: {nil, agg}

  def finish(
        %__MODULE__{agg_partition_key: agg_pk, agg_explicit_hash_key: agg_ehk} = agg,
        should_deflate?
      ) do
    agg_record = {agg_pk, serialize_data(agg, should_deflate?), agg_ehk}
    {agg_record, new(max_bytes_per_record: agg.max_bytes_per_record)}
  end

  def finish(agg), do: finish(agg, false)

  @spec add(t(), {key(), binary()} | {key(), binary(), key()}) ::
          {aggregated_record() | nil, t()}
  def add(agg, {partition_key, data}) do
    add(agg, {partition_key, data, create_explicit_hash_key(partition_key)})
  end

  def add(%{max_bytes_per_record: max} = agg, {partition_key, data, explicit_hash_key}) do
    case {calc_record_size(agg, partition_key, data, explicit_hash_key), size_bytes(agg)} do
      {rec_size, _} when rec_size > max ->
        Logger.error(fn -> "input record too large to fit in a single Kinesis record" end)
        {nil, agg}

      {rec_size, cur_size} when rec_size + cur_size > max ->
        {full_record, agg1} = finish(agg)
        agg2 = add_record(agg1, partition_key, data, explicit_hash_key, rec_size)
        {full_record, agg2}

      {rec_size, _} ->
        agg1 = add_record(agg, partition_key, data, explicit_hash_key, rec_size)

        # FIXME make size calculations more accurate
        case size_bytes(agg1) > max - 64 do
          true ->
            {full_record, agg2} = finish(agg)
            agg3 = add_record(agg2, partition_key, data, explicit_hash_key, rec_size)
            {full_record, agg3}

          false ->
            {nil, agg1}
        end
    end
  end

  @spec add_all(t(), [user_record()]) :: {[aggregated_record()], t()}
  def add_all(agg, records) do
    {rev_agg_records, new_agg} =
      List.foldl(records, {[], agg}, fn record, {rev_agg_records, agg} ->
        case add(agg, record) do
          {nil, new_agg} -> {rev_agg_records, new_agg}
          {agg_record, new_agg} -> {[agg_record | rev_agg_records], new_agg}
        end
      end)

    {Enum.reverse(rev_agg_records), new_agg}
  end

  defp add_record(
         %__MODULE__{
           partition_keyset: pkset,
           explicit_hash_keyset: ehkset,
           rev_records: rev_records,
           num_user_records: num_user_records,
           agg_size_bytes: agg_size,
           agg_partition_key: agg_pk,
           agg_explicit_hash_key: agg_ehk,
           max_bytes_per_record: max_bytes_per_record
         },
         partition_key,
         data,
         explicit_hash_key,
         new_record_size
       ) do
    {pk_index, new_pk_set} = Keyset.get_or_add_key(partition_key, pkset)
    {ehk_index, new_ehk_set} = Keyset.get_or_add_key(explicit_hash_key, ehkset)

    new_record = %Proto.Record{
      partition_key_index: pk_index,
      explicit_hash_key_index: ehk_index,
      data: data
    }

    %__MODULE__{
      partition_keyset: new_pk_set,
      explicit_hash_keyset: new_ehk_set,
      rev_records: [new_record | rev_records],
      num_user_records: 1 + num_user_records,
      agg_size_bytes: new_record_size + agg_size,
      agg_partition_key: first_defined(agg_pk, partition_key),
      agg_explicit_hash_key: first_defined(agg_ehk, explicit_hash_key),
      max_bytes_per_record: max_bytes_per_record
    }
  end

  defp first_defined(nil, second), do: second
  defp first_defined(first, _), do: first

  defp calc_record_size(
         %__MODULE__{partition_keyset: pkset, explicit_hash_keyset: ehkset},
         partition_key,
         data,
         explicit_hash_key
       ) do
    pk_length = byte_size(partition_key)

    pk_size =
      case Keyset.key?(partition_key, pkset) do
        true -> 0
        false -> 1 + varint_size(pk_length) + pk_length
      end

    ehk_size =
      case explicit_hash_key do
        nil ->
          0

        _ ->
          ehk_length = byte_size(explicit_hash_key)

          case Keyset.key?(explicit_hash_key, ehkset) do
            true -> 0
            false -> 1 + varint_size(ehk_length) + ehk_length
          end
      end

    pk_index_size = 1 + varint_size(Keyset.potential_index(partition_key, pkset))

    ehk_index_size =
      case explicit_hash_key do
        nil -> 0
        _ -> 1 + varint_size(Keyset.potential_index(explicit_hash_key, ehkset))
      end

    data_length = byte_size(data)
    data_size = 1 + varint_size(data_length) + data_length
    inner_size = pk_index_size + ehk_index_size + data_size
    pk_size + ehk_size + 1 + varint_size(inner_size) + inner_size
  end

  defp varint_size(int) when int >= 0 do
    bits = max(num_bits(int, 0), 1)
    div(bits + 6, 7)
  end

  defp num_bits(0, acc), do: acc

  defp num_bits(int, acc) when int >= 0 do
    num_bits(bsr(int, 1), acc + 1)
  end

  # Calculate a new explicit hash key based on the input partition key
  # (following the algorithm from the original KPL).
  # create_explicit_hash_key(_PartitionKey) ->
  # Their python implementation [1] is broken compared to the C++
  # implementation [2]. But we don't care about EHKs anyway.
  # [1] https://github.com/awslabs/kinesis-aggregation/blob/db92620e435ad9924356cda7d096e3c888f0f72f/python/aws_kinesis_agg/aggregator.py#L447-L458
  # [2] https://github.com/awslabs/amazon-kinesis-producer/blob/ea1e49218e1a11f1b462662a1db4cc06ddad39bb/aws/kinesis/core/user_record.cc#L36-L45
  # FIXME: Implement the actual algorithm from KPL.
  defp create_explicit_hash_key(_), do: nil

  defp serialize_data(
         %__MODULE__{
           partition_keyset: pkset,
           explicit_hash_keyset: ehkset,
           rev_records: records
         },
         should_deflate?
       ) do
    {serialized_iodata, _byte_size} =
      %Proto.AggregatedRecord{
        partition_key_table: Keyset.key_list(pkset),
        explicit_hash_key_table: Keyset.key_list(ehkset),
        records: Enum.reverse(records)
      }
      |> Protox.encode!()

    serialized = IO.iodata_to_binary(serialized_iodata)
    data = serialized <> :crypto.hash(:md5, serialized)

    case should_deflate? do
      true ->
        @magic_deflated <> :zlib.compress(data)

      false ->
        @magic <> data
    end
  end

  defp pk_size(nil), do: 0
  defp pk_size(pk), do: byte_size(pk)
end
