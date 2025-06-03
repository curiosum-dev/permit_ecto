defmodule Permit.Ecto do
  @moduledoc """
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

  iex> MyApp.Permissions.accessible_by!(%MyApp.Users.User{id: 1}, :update, MyApp.Blog.Article) |> MyApp.Repo.all()
  [%MyApp.Blog.Article{id: 1, ...}, %MyApp.Blog.Article{id: 2, ...}]

  iex> MyApp.Permissions.accessible_by!(%MyApp.Users.User{id: 1}, :read, MyApp.Blog.Article) |> MyApp.Repo.all()
  [%MyApp.Blog.Article{id: 1, ...}, %MyApp.Blog.Article{id: 2, ...}, %MyApp.Blog.Article{id: 3, ...}]

  iex> MyApp.Permissions.accessible_by!(%MyApp.Users.User{id: 3, role: :admin}, :update, MyApp.Blog.Article) |> MyApp.Repo.all()
  [%MyApp.Blog.Article{id: 1, ...}, %MyApp.Blog.Article{id: 2, ...}, %MyApp.Blog.Article{id: 3, ...}]
  ```
  """

  defmacro __using__(opts) do
    alias Permit.Types

    alias Permit.Ecto.Permissions
    alias Permit.Ecto.UnconvertibleConditionError
    alias Permit.Ecto.UndefinedConditionError

    quote do
      use Permit, unquote(opts)

      require Ecto.Query

      @spec repo() :: Ecto.Repo.t()
      def repo, do: unquote(opts[:repo])

      @doc """
      Returns an Ecto query that filters resources based on the current user's permissions
      for the given action.

      This function constructs an Ecto query that only includes records the user is authorized
      to access based on their permissions. It returns a tuple with `:ok` and the query on
      success, or `:error` with details on failure.

      ## Parameters

      - `current_user` - The subject (user) whose permissions should be checked
      - `action` - The action being performed (e.g., `:read`, `:update`, `:delete`)
      - `resource` - The resource module or struct being accessed
      - `opts` - Optional configuration map with keys:
        - `:base_query` - Optional function to generate the base query (Permit.Ecto.Types.base_query())

      ## Returns

      - `{:ok, Ecto.Query.t()}` - Success with the filtered query
      - `{:error, {:undefined_condition, key}}` - When a condition key is undefined
      - `{:error, {:condition_unconvertible, details}}` - When conditions cannot be converted to Ecto queries

      ## Example

          iex> MyApp.Authorization.accessible_by(user, :update, MyApp.Blog.Article)
          {:ok, #Ecto.Query<from a0 in MyApp.Blog.Article, where: a0.author_id == ^1>}

      """
      @spec accessible_by(
              Types.subject(),
              Types.action_group(),
              Types.object_or_resource_module(),
              map()
            ) ::
              {:ok, Ecto.Query.t()} | {:error, term()}
      def accessible_by(current_user, action, resource, opts \\ %{}) do
        opts =
          opts
          |> Map.put_new(:params, %{})
          |> Map.put_new(:base_query, fn %{resource_module: resource_module} ->
            Ecto.Query.from(_ in resource_module)
          end)

        current_user
        |> can()
        |> Map.get(:permissions)
        |> Permissions.construct_query(
          action,
          resource,
          current_user,
          actions_module(),
          opts
        )
      end

      @doc """
      Returns an Ecto query that filters resources based on the current user's permissions
      for the given action, raising an exception on failure.

      This is the bang variant of `accessible_by/4`. It returns the query directly on success
      but raises an exception if the permissions cannot be converted to a valid Ecto query.

      ## Parameters

      - `current_user` - The subject (user) whose permissions should be checked
      - `action` - The action being performed (e.g., `:read`, `:update`, `:delete`)
      - `resource` - The resource module or struct being accessed
      - `opts` - Optional configuration map (same as `accessible_by/4`)

      ## Returns

      - `Ecto.Query.t()` - The filtered query on success

      ## Raises

      - `Permit.Ecto.UndefinedConditionError` - When a condition key is undefined
      - `Permit.Ecto.UnconvertibleConditionError` - When conditions cannot be converted

      ## Example

          iex> MyApp.Authorization.accessible_by!(user, :update, MyApp.Blog.Article)
          #Ecto.Query<from a0 in MyApp.Blog.Article, where: a0.author_id == ^1>

      """
      @spec accessible_by!(
              Types.subject(),
              Types.action_group(),
              Types.object_or_resource_module(),
              map()
            ) ::
              Ecto.Query.t()
      def accessible_by!(current_user, action, resource, opts \\ %{}) do
        case accessible_by(current_user, action, resource, opts) do
          {:ok, query} ->
            query

          {:error, {:undefined_condition, key}} ->
            raise UndefinedConditionError, key

          {:error, errors} ->
            raise UnconvertibleConditionError, errors
        end
      end

      @impl Permit
      def resolver_module, do: Permit.Ecto.Resolver
    end
  end

  require Ecto.Query

  @doc false
  @spec from(Ecto.Queryable.t()) :: Ecto.Query.t()
  def from(queryable) do
    Ecto.Query.from(queryable)
  end

  @doc false
  def filter_by_field(query, field_name, value) do
    query
    |> Ecto.Query.where([it], field(it, ^field_name) == ^value)
  end
end
