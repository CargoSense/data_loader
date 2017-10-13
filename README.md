# DataLoader

Dataloader exists as a way to efficiently load data in batches, lazily. It's inspired by https://github.com/facebook/dataloader, although it makes some small API changes to better suite Elixir use cases.

```
source =
```

Central to DataLoader is the idea of a source. A single DataLoader struct can have many different sources, which represent different ways to l

## Ecto Usage

DataLoader ships with an Ecto integration for cleanly working with the SQL databases that Ecto supports. Primary differences from the ordinary KV store is the support for Ecto associations.

## GraphQL Usage



## Phoenix Context Notes



## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `data_loader` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:data_loader, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/data_loader](https://hexdocs.pm/data_loader).
