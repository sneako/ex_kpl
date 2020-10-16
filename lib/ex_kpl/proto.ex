defmodule ExKpl.Proto do
  use Protox, files: [Path.expand("proto/kpl_agg.proto", __DIR__)]
end
