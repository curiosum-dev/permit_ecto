<div align="center">
  <img src="https://github.com/user-attachments/assets/f0352656-397d-4d90-999a-d3adbae1095f">

  # Permit.Ecto
  <p><strong>Ecto integration for Permit - Convert permissions to Ecto queries with automatic authorization scoping.
</strong></p>

  [![Contact Us](https://img.shields.io/badge/Contact%20Us-%23F36D2E?style=for-the-badge&logo=maildotru&logoColor=white&labelColor=F36D2E)](https://curiosum.com/contact)
  [![Visit Curiosum](https://img.shields.io/badge/Visit%20Curiosum-%236819E6?style=for-the-badge&logo=elixir&logoColor=white&labelColor=6819E6)](https://curiosum.com/services/elixir-software-development)
  [![License: MIT](https://img.shields.io/badge/License-MIT-1D0642?style=for-the-badge&logo=open-source-initiative&logoColor=white&labelColor=1D0642)]()
</div>


<br/>

## Purpose and usage

Permit.Ecto integrates [`Permit`](https://github.com/curiosum-dev/permit) with Ecto, providing means to convert permissions to Ecto queries and automatically constructing `Ecto.Query` scopes to preload records that meet authorization criteria.

Key features:
- **Automatic query generation** - Convert Permit permissions into Ecto queries
- **Authorization scoping** - Automatically scope database queries based on user permissions
- **Association support** - Handle has_one, has_many, and belongs_to relationships in permission rules
- **Seamless integration** - Works with Permit.Phoenix for automatic controller and LiveView authorization

[![Hex version badge](https://img.shields.io/hexpm/v/permit_ecto.svg)](https://hex.pm/packages/permit_ecto)
[![Actions Status](https://github.com/curiosum-dev/permit_ecto/actions/workflows/elixir.yml/badge.svg)](https://github.com/curiosum-dev/permit_ecto/actions)
[![Code coverage badge](https://img.shields.io/codecov/c/github/curiosum-dev/permit_ecto/master.svg)](https://codecov.io/gh/curiosum-dev/permit_ecto/branch/master)
[![License badge](https://img.shields.io/hexpm/l/permit_ecto.svg)](https://github.com/curiosum-dev/permit_ecto/blob/master/LICENSE.md)

## Dependencies and related libraries

`Permit.Ecto` depends on `Permit`. It can be used to build custom integrations or in conjunction with `Permit.Phoenix`, which uses the generated `accessible_by/4` functions to automatically preload, authorize and inject records loaded via Ecto into controller assigns (see more in [`Permit.Phoenix documentation`](https://github.com/curiosum-dev/permit_phoenix)).

## Usage

```elixir
defmodule MyApp.Authorization do
  use Permit.Ecto,
    permissions_module: MyApp.Permissions,
    repo: MyApp.Repo
end

defmodule MyApp.Permissions do
  use Permit.Ecto.Permissions, actions_module: Permit.Actions.CrudActions

  def can(%{role: :admin} = user) do
    permit()
    |> all(MyApp.Blog.Article)
  end

  def can(%{id: user_id} = user) do
    # Checks can be performed directly for record columns as well as associated
    # record values in has_one, has_many and belongs_to associations.
    #
    # For has_one and belongs_to relationships, given condition must be satisfied
    # for the associated record. For has_many relationships, at least one associated
    # record must satisfy the condition - as seen in example below.

    permit()
    |> all(MyApp.Blog.Article, author_id: user_id)
    |> read(MyApp.Blog.Article, reviews: [approved: true])
  end

  def can(user), do: permit()
end

iex> MyApp.Repo.all(MyApp.Blog.Article)
[
  %MyApp.Blog.Article{id: 1, author_id: 1},
  %MyApp.Blog.Article{id: 2, author_id: 1},
  %MyApp.Blog.Article{id: 3, author_id: 2}
]

# The `accessible_by!/3` function also has a `accessible_by/3` variant which returns `{:ok, ...}` tuples.

iex> MyApp.Permissions.accessible_by!(%MyApp.Users.User{id: 1}, :update, MyApp.Blog.Article) |> MyApp.Repo.all()
[%MyApp.Blog.Article{id: 1, ...}, %MyApp.Blog.Article{id: 2, ...}]

iex> MyApp.Permissions.accessible_by!(%MyApp.Users.User{id: 1}, :read, MyApp.Blog.Article) |> MyApp.Repo.all()
[%MyApp.Blog.Article{id: 1, ...}, %MyApp.Blog.Article{id: 2, ...}, %MyApp.Blog.Article{id: 3, ...}]

iex> MyApp.Permissions.accessible_by!(%MyApp.Users.User{id: 3, role: :admin}, :update, MyApp.Blog.Article) |> MyApp.Repo.all()
[%MyApp.Blog.Article{id: 1, ...}, %MyApp.Blog.Article{id: 2, ...}, %MyApp.Blog.Article{id: 3, ...}]
```

### Quick authorization checks

Generate Ecto queries based on permissions for direct database querying:

```elixir
# Generate query scoped to user permissions
query = MyApp.Authorization.accessible_by!(current_user, :read, Article)
articles = MyApp.Repo.all(query)

# Use with pagination and other Ecto features
query
|> where([a], a.published == true)
|> order_by([a], desc: a.inserted_at)
|> limit(10)
|> MyApp.Repo.all()
```

## Ecosystem

Permit.Ecto is part of the modular Permit ecosystem:

| Package | Version | Description |
|---------|---------|-------------|
| **[permit](https://hex.pm/packages/permit)** | [![Hex.pm](https://img.shields.io/hexpm/v/permit.svg)](https://hex.pm/packages/permit) | Core authorization library |
| **[permit_ecto](https://hex.pm/packages/permit_ecto)** | [![Hex.pm](https://img.shields.io/hexpm/v/permit_ecto.svg)](https://hex.pm/packages/permit_ecto) | Ecto integration for database queries |
| **[permit_phoenix](https://hex.pm/packages/permit_phoenix)** | [![Hex.pm](https://img.shields.io/hexpm/v/permit_phoenix.svg)](https://hex.pm/packages/permit_phoenix) | Phoenix Controllers & LiveView integration |
| **[permit_absinthe](https://github.com/curiosum-dev/permit_absinthe)** | [![Hex.pm](https://img.shields.io/hexpm/v/permit_absinthe.svg)](https://hex.pm/packages/permit_absinthe) | GraphQL API authorization via Absinthe |

## Installation

The package can be installed by adding `permit_ecto` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:permit, "~> 0.3.0"},        # Core authorization library
    {:permit_ecto, "~> 0.2.4"}    # Ecto integration
  ]
end
```

For a complete setup with Phoenix or Absinthe integration, add `:permit_phoenix` or `:permit_absinthe`.

## Documentation

- **Permit.Ecto docs**: [hexdocs.pm/permit_ecto](https://hexdocs.pm/permit_ecto)
- **Core library**: [hexdocs.pm/permit](https://hexdocs.pm/permit)

## Contributing

We welcome contributions! Please see our [Contributing Guide](https://github.com/curiosum-dev/permit_ecto/blob/master/CONTRIBUTING.md) for details.

### Development setup

Just clone the repository, install dependencies normally, develop and run tests. When running Credo and Dialyzer, please use `MIX_ENV=test` to ensure tests and support files are validated, too.

### Community

- **Slack channel**: [Elixir Slack / #permit](https://elixir-lang.slack.com/archives/C091Q5S0GDU)
- **Issues**: [GitHub Issues](https://github.com/curiosum-dev/permit_ecto/issues)
- **Discussions**: [GitHub Discussions](https://github.com/curiosum-dev/permit/discussions)
- **Blog**: [Curiosum Blog](https://curiosum.com/blog?search=permit)

## Contact

* Library maintainer: [Michał Buszkiewicz](https://github.com/vincentvanbush)
* [**Curiosum**](https://curiosum.com) - Elixir development team behind Permit

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
