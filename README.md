# ExKpl [![Build Status](https://travis-ci.org/sneako/ex_kpl.svg?branch=master)](https://travis-ci.org/sneako/ex_kpl)

[Kinesis Producer Library](https://docs.aws.amazon.com/streams/latest/dev/developing-producers-with-kpl.html) in Elixir

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `exkpl` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ex_kpl, "~> 0.1.0"}
  ]
end
```

## Credits
This is basically a port of AdRoll's Erlang implementation included in [adroll/erlmld](https://github.com/AdRoll/erlmld), so a special thanks to them.
