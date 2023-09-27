defmodule Permit.Ecto.Permissions do
  @moduledoc ~S"""
  Defines the application's permission set. Replaces `Permit.Permissions` when
  `Permit.Ecto` is used, but its syntax is identical.

  ## Example

  ```
  defmodule MyApp.Permissions do
    use Permit.Permissions, actions_module: Permit.Actions.CrudActions

    @impl true
    def can(%MyApp.User{role: :admin}) do
      permit()
      |> all(Article)
    end

    def can(%MyApp.User{id: user_id}) do
      permit()
      |> read(Article)
      |> all(Article, author_id: user_id)
    end

    def can(_), do: permit()
  end
  ```

  ## Condition conversion

  Conditions defined using standard operators such as equality, inequality, greater-than, less-than,
  LIKE and ILIKE are converted automatically (see `Permit.Operators`).

  Other conditions, such as those given as functions,

  Refer to `Permit.Permissions` documentation for more examples of usage.

  """

  import Ecto.Query

  alias Permit.Actions
  alias Permit.Ecto.Permissions.ConditionParser
  alias Permit.Ecto.Permissions.DynamicQueryJoiner
  alias Permit.Ecto.Types.ConditionTypes
  alias Permit.Permissions
  alias Permit.Types

  import Permit.Helpers, only: [resource_module_from_resource: 1]

  defmacro __using__(opts) do
    extended_opts =
      [
        {:condition_parser, &ConditionParser.build/2},
        {:condition_types_module, ConditionTypes}
      ] ++ opts

    quote do
      use Permit.Permissions, unquote(extended_opts)

      import unquote(__MODULE__)
    end
  end

  @spec construct_query(
          Permissions.t(),
          Types.action_group(),
          Types.object_or_resource_module(),
          Types.subject(),
          module(),
          map()
        ) ::
          {:ok, Ecto.Query.t()} | {:error, term()}
  def construct_query(
        permissions,
        action,
        resource,
        subject,
        actions_module,
        opts \\ %{}
      ) do
    with {:ok, filter} <- transitive_query(permissions, actions_module, action, resource, subject) do
      # base_query is (Types.object_or_resource_module() -> Ecto.Query.t())
      # params = Map.get(opts, :params, %{})

      resource_module = resource_module_from_resource(resource)

      base_query =
        Map.get(opts, :base_query, fn %{resource_module: resource_module} ->
          Ecto.Query.from(_ in resource_module)
        end)

      ctx =
        %{
          action: action,
          resource_module: resource_module,
          subject: subject
        }
        |> Map.merge(opts)

      ctx
      |> base_query.()
      |> where(^filter)
      |> then(&{:ok, &1})
    end
  end

  defp transitive_query(permissions, actions_module, action, resource, subject) do
    res_module = resource_module_from_resource(resource)

    value_fn = fn action ->
      case Map.get(permissions.conditions_map, {action, res_module}) do
        nil -> {:ok, dynamic(false)}
        dnf -> DynamicQueryJoiner.to_dynamic_query(dnf, subject, resource)
      end
    end

    empty = &throw({:undefined_condition, {&1, res_module}})

    conj = fn
      [] ->
        :nothing

      l ->
        Enum.reduce(l, &conj_queries/2)
    end

    disj = fn
      [] ->
        :nothing

      l ->
        Enum.reduce(l, &disj_queries/2)
    end

    try do
      Actions.traverse_actions!(
        actions_module,
        action,
        value_fn,
        empty,
        conj,
        disj
      )
    catch
      {:undefined_condition, _} = error ->
        {:error, error}
    end
  end

  defp conj_queries(:nothing, {:ok, query}), do: {:ok, query}

  defp conj_queries({:ok, query}, :nothing), do: {:ok, query}

  defp conj_queries(:nothing, :nothing), do: :nothing

  defp conj_queries({:ok, query1}, {:ok, query2}),
    do: {:ok, dynamic(^query1 and ^query2)}

  defp conj_queries({:error, errors}, _),
    do: {:error, errors}

  defp conj_queries(_, {:error, errors}),
    do: {:error, errors}

  defp conj_queries({:error, err1}, {:error, err2}),
    do: {:error, err1 ++ err2}

  defp disj_queries(:nothing, {:ok, query}), do: {:ok, query}

  defp disj_queries({:ok, query}, :nothing), do: {:ok, query}

  defp disj_queries(:nothing, :nothing), do: :nothing

  defp disj_queries({:ok, query1}, {:ok, query2}),
    do: {:ok, dynamic(^query1 or ^query2)}

  defp disj_queries({:error, errors}, _),
    do: {:error, errors}

  defp disj_queries(_, {:error, errors}),
    do: {:error, errors}

  defp disj_queries({:error, err1}, {:error, err2}),
    do: {:error, err1 ++ err2}
end
