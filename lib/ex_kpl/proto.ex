defmodule ExKpl.Proto do
  use Protobuf, from: Path.expand("../../proto/kpl_agg.proto", __DIR__)
end
