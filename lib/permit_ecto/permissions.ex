defmodule Permit.Ecto.Permissions do
  import Ecto.Query

  alias Permit.Types
  alias Permit.Actions
  alias Permit.Ecto.Permissions.DisjunctiveNormalForm, as: DNF

  import Permit.Permissions, only: [resource_module_from_resource: 1]

  @spec construct_query(
          Permissions.t(),
          Types.action_group(),
          Types.resource(),
          Types.subject(),
          module(),
          keyword()
        ) ::
          {:ok, Ecto.Query.t()} | {:error, [term()]}
  def construct_query(
        permissions,
        action,
        resource,
        subject,
        actions_module,
        opts \\ []
      ) do
    with {:ok, filter} <- transitive_query(permissions, actions_module, action, resource, subject) do
      # base_query is (Types.resource() -> Ecto.Query.t())
      params = Keyword.get(opts, :params, %{})

      resource_module = resource_module_from_resource(resource)

      base_query =
        Keyword.get(opts, :base_query, fn _action, resource_module, _params ->
          Ecto.Query.from(_ in resource_module)
        end)

      base_query.(action, resource_module, subject, params)
      |> where(^filter)
      |> then(&{:ok, &1})
    end
  end

  defp transitive_query(permissions, actions_module, action, resource, subject) do
    res_module = resource_module_from_resource(resource)

    condition = &conditions_defined_for?(permissions, &1, res_module)

    value = fn action ->
      permissions.conditions_map
      |> Map.get({action, res_module})
      |> DNF.to_dynamic_query(subject, resource)
    end

    empty = &throw({:undefined_condition, {&1, res_module}})
    join = fn l -> Enum.reduce(l, &join_queries/2) end

    try do
      Actions.traverse_actions!(
        actions_module,
        action,
        condition,
        value,
        empty,
        join
      )
    catch
      {:undefined_condition, _} = error ->
        {:error, error}
    end
  end

  @spec conditions_defined_for?(Permissions.t(), Types.controller_action(), Types.resource()) ::
          boolean()
  defp conditions_defined_for?(permissions, action, resource) do
    permissions.conditions_map[{action, resource}]
    |> case do
      nil -> false
      _ -> true
    end
  end

  defp join_queries({:ok, query1}, {:ok, query2}),
    do: {:ok, query1 and query2}

  defp join_queries({:error, errors}, {:ok, _}),
    do: {:error, errors}

  defp join_queries({:ok, _}, {:error, errors}),
    do: {:error, errors}

  defp join_queries({:error, err1}, {:error, err2}),
    do: {:error, err1 ++ err2}
end
