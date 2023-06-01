defmodule Permit.Ecto do
  defmacro __using__(opts) do
    alias Permit.Types

    alias Permit.Ecto.Permissions.UndefinedConditionError
    alias Permit.Ecto.Permissions.UnconvertibleConditionError

    quote do
      use Permit, unquote(opts)

      require Ecto.Query

      @spec repo() :: Ecto.Repo.t()
      def repo, do: unquote(opts[:repo])

      @spec accessible_by(
              Types.subject(),
              Types.action_group(),
              Types.resource(),
              keyword()
            ) ::
              {:ok, Ecto.Query.t()} | {:error, term()}
      def accessible_by(current_user, action, resource, opts \\ []) do
        # base_query is (Types.resource() -> Ecto.Query.t())
        opts =
          opts
          |> Keyword.put_new(:params, %{})
          |> Keyword.put_new(:base_query, fn _action, resource_module, _subject, _params ->
            Ecto.Query.from(_ in resource_module)
          end)

        current_user
        |> can()
        |> Map.get(:permissions)
        |> Permit.Ecto.Permissions.construct_query(
          action,
          resource,
          current_user,
          actions_module(),
          opts
        )
      end

      @spec accessible_by!(
              Types.subject(),
              Types.action_group(),
              Types.resource(),
              keyword()
            ) ::
              Ecto.Query.t()
      def accessible_by!(current_user, action, resource, opts \\ []) do
        case accessible_by(current_user, action, resource, opts) do
          {:ok, query} ->
            query

          {:error, {:undefined_condition, key}} ->
            raise UndefinedConditionError, key

          {:error, errors} ->
            raise UnconvertibleConditionError, errors
        end
      end

      def resolver_module, do: Permit.Ecto.Resolver
    end
  end

  require Ecto.Query

  @spec from(Ecto.Queryable.t()) :: Ecto.Query.t()
  def from(queryable) do
    Ecto.Query.from(queryable)
  end

  def filter_by_field(query, field_name, value) do
    query
    |> Ecto.Query.where([it], field(it, ^field_name) == ^value)
  end
end
