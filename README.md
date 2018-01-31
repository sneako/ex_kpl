# ExKpl [![Coverage Status](https://coveralls.io/repos/github/sneako/ex_kpl/badge.svg?branch=master)](https://coveralls.io/github/sneako/ex_kpl?branch=master) [![Build Status](https://travis-ci.org/sneako/ex_kpl.svg?branch=master)](https://travis-ci.org/sneako/ex_kpl)

[Kinesis Producer Library](https://docs.aws.amazon.com/streams/latest/dev/developing-producers-with-kpl.html) in Elixir

## Documentation
Available on [hex](https://hexdocs.pm/ex_kpl/api-reference.html)

## Installation

The package can be installed
by adding `ex_kpl` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ex_kpl, "~> 0.1.1"}
  ]
end
```

## Credits
This is basically a port of AdRoll's Erlang implementation included in [adroll/erlmld](https://github.com/AdRoll/erlmld), so a special thanks to them.
