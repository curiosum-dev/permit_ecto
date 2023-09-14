# Permit.Ecto

Integrates [`Permit`](https://github.com/curiosum-dev/permit) with Ecto, providing means to convert permissions to Ecto queries,
automatically constructing `Ecto.Query` scopes to preload records that meet authorization criteria.

## Dependencies and related libraries

`Permit.Ecto` depends on `Permit`. It can be used to build custom integrations or in conjunction with `Permit.Phoenix`, which uses
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
    permit()
    |> all(MyApp.Blog.Article, author_id: user_id)
    |> read(MyApp.Blog.Article)
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
    {:permit_ecto, "~> 0.1.0"}
  ]
end
```

The docs can be found at <https://hexdocs.pm/permit_ecto>.

