# Operating System: macOS
# CPU Information: Intel(R) Core(TM) i9-9880H CPU @ 2.30GHz
# Number of Available Cores: 16
# Available memory: 16 GB
# Elixir 1.11.0
# Erlang 23.1.1

# Benchmark suite executing with the following configuration:
# warmup: 2 s
# time: 5 s
# memory time: 0 ns
# parallel: 1
# inputs: none specified
# Estimated total run time: 7 s

# Benchmarking full example...

# Name                   ips        average  deviation         median         99th %
# exprotobuf          865.62        1.16 ms    ±14.34%        1.10 ms        1.90 ms
# protox              7.56 K      132.36 μs    ±24.01%         123 μs         287 μs

Benchee.run(%{
  "full example" => fn -> 
    Enum.reduce(1..100, ExKpl.new(), fn _, agg ->
      {nil, agg} = ExKpl.add(agg, {"pk", "dataaaaa", "ehk"})
      agg
    end)
    |> ExKpl.finish()
  end
})
