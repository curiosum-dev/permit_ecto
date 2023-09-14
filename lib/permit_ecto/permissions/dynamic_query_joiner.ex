defmodule Permit.Ecto.Permissions.DynamicQueryJoiner do
  @moduledoc """
  Joins a DNF of conditions represented by a `Permit.Permissions.DisjunctiveNormalForm`
  into an Ecto dynamic query.

  Part of the private API, subject to changes and not to be used on the
  application level.
  """

  import Ecto.Query

  alias Permit.Ecto.Permissions.Conjunction
  alias Permit.Permissions.DisjunctiveNormalForm
  alias Permit.Types

  @spec to_dynamic_query(
          DisjunctiveNormalForm.t(),
          Types.object_or_resource_module(),
          Types.subject()
        ) ::
          {:ok, Ecto.Query.t()} | {:error, term()}
  def to_dynamic_query(%DisjunctiveNormalForm{disjunctions: disjunctions}, subject, resource) do
    disjunctions
    |> Enum.map(&Conjunction.to_dynamic_query_expr(&1, subject, resource))
    |> case do
      [] -> {:ok, dynamic(false)}
      li -> Enum.reduce(li, &join_queries/2)
    end
  end

  #######

  defp join_queries({:ok, conditions_query}, {:ok, acc}),
    do: {:ok, dynamic(^acc or ^conditions_query)}

  defp join_queries({:ok, _}, {:error, errors}),
    do: {:error, errors}

  defp join_queries({:error, err1}, {:error, err2}) when is_tuple(err2),
    do: {:error, [err1, err2]}

  defp join_queries({:error, error}, {:error, errors}) when is_list(errors),
    do: {:error, [error | errors]}

  defp join_queries({:error, error}, {:ok, _}),
    do: {:error, [error]}

  defp join_queries({:error, es}, {:error, errors}),
    do: {:error, es ++ errors}
end
