defmodule Permit.Ecto.Permissions.Conjunction do
  @moduledoc false
  import Ecto.Query

  alias Permit.Ecto.EctoParsedCondition
  alias Permit.Permissions.ConditionClauses
  alias Permit.Types

  @spec to_dynamic_query_expr(ConditionClauses.t(), Types.resource(), Types.subject()) ::
          {:ok, Ecto.Query.DynamicExpr.t()} | {:error, keyword()}
  def to_dynamic_query_expr(%ConditionClauses{conditions: []}, _, _),
    do: {:ok, dynamic(false)}

  def to_dynamic_query_expr(%ConditionClauses{conditions: conditions}, subject, resource) do
    conditions
    |> Enum.map(&EctoParsedCondition.to_dynamic_query(&1, subject, resource))
    |> case do
      [] ->
        {:ok, dynamic(true)}

      [{:error, error}] when not is_list(error) ->
        {:error, [error]}

      list ->
        Enum.reduce(list, &join_queries/2)
    end
  end

  defp join_queries({:ok, condition_query}, {:ok, acc}),
    do: {:ok, dynamic(^acc and ^condition_query)}

  defp join_queries({:ok, _}, {:error, errors}),
    do: {:error, errors}

  defp join_queries({:error, err1}, {:error, err2}) when is_tuple(err2),
    do: {:error, [err1, err2]}

  defp join_queries({:error, error}, {:error, errors}) when is_list(errors),
    do: {:error, [error | errors]}

  defp join_queries({:error, error}, {:ok, _}),
    do: {:error, [error]}
end
