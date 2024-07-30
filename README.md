# Permit.Ecto

[![Hex version badge](https://img.shields.io/hexpm/v/permit_ecto.svg)](https://hex.pm/packages/permit_ecto)
[![Actions Status](https://github.com/curiosum-dev/permit_ecto/actions/workflows/elixir.yml/badge.svg)](https://github.com/curiosum-dev/permit_ecto/actions)
[![Code coverage badge](https://img.shields.io/codecov/c/github/curiosum-dev/permit_ecto/master.svg)](https://codecov.io/gh/curiosum-dev/permit_ecto/branch/master)
[![License badge](https://img.shields.io/hexpm/l/permit_ecto.svg)](https://github.com/curiosum-dev/_ecto/blob/master/LICENSE.md)

Integrates [`Permit`](https://github.com/curiosum-dev/permit) with Ecto, providing means to convert permissions to Ecto queries,
automatically constructing `Ecto.Query` scopes to preload records that meet authorization criteria.

## Dependencies and related libraries

`Permit.Ecto` depends on `Permit`. It can be used to build custom integrations or in conjunction with `Permit.Phoenix`, which usespermit
the generated `accessible_by/4` functions to automatically preload, authorize and inject records loaded via Ecto into
controller assigns (see more in [`Permit.Phoenix documentation`](https://github.com/curiosum-dev/permit_phoenix)).

## Configuration

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

iex> MyApp.Permissions.accessible_by!(%MyApp.Users.User{id: 1}, :update, MyApp.Blog.Article)
[%MyApp.Blog.Article{id: 1, ...}, %MyApp.Blog.Article{id: 2, ...}]

iex> MyApp.Permissions.accessible_by!(%MyApp.Users.User{id: 1}, :read, MyApp.Blog.Article)
[%MyApp.Blog.Article{id: 1, ...}, %MyApp.Blog.Article{id: 2, ...}, %MyApp.Blog.Article{id: 3, ...}]

iex> MyApp.Permissions.accessible_by!(%MyApp.Users.User{id: 3, role: :admin}, :update, MyApp.Blog.Article)
[%MyApp.Blog.Article{id: 1, ...}, %MyApp.Blog.Article{id: 2, ...}, %MyApp.Blog.Article{id: 3, ...}]
```


## Installation

The package can be installed by adding `permit_ecto` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:permit_ecto, "~> 0.2.2"}
  ]
end
```

The docs can be found at <https://hexdocs.pm/permit_ecto>.

