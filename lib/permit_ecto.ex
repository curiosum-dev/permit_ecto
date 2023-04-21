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
      # TODO: prefilter should be 3-arg
      def accessible_by(current_user, action, resource, opts \\ []) do
        # prefilter is (Types.resource() -> Ecto.Query.t())
        opts =
          opts
          |> Keyword.put_new(:params, %{})
          |> Keyword.put_new(:prefilter, fn _action, resource_module, _params ->
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
end
