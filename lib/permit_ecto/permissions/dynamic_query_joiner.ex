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
          Types.subject(),
          Types.object_or_resource_module(),
          Ecto.Query.t()
        ) ::
          {:ok, Ecto.Query.t(), Ecto.Query.t()} | {:error, Ecto.Query.t(), term()}
  def to_dynamic_query(
        %DisjunctiveNormalForm{disjunctions: disjunctions},
        subject,
        resource,
        base_query
      ) do
    query = construct_query_with_joins(disjunctions, base_query)

    disjunctions
    |> Enum.map(&Conjunction.to_dynamic_query_expr(&1, subject, resource, query))
    |> case do
      [] ->
        {:ok, query, dynamic(false)}

      conditions ->
        conditions
        |> Enum.reduce(&join_queries/2)
        |> format_response(query)
    end
  end

  defp extract_assocs(disjunctions) do
    disjunctions
    |> Enum.flat_map(& &1.conditions)
    |> Enum.reduce([], &check_assoc_path/2)
  end

  defp construct_query_with_joins(disjunctions, base_query) do
    disjunctions
    |> extract_assocs()
    |> add_joins(base_query)
  end

  def add_joins(joins, base_query) do
    Enum.reduce(joins, base_query, fn {key, values}, acc ->
      acc = join(acc, :inner, [p, ...], _ in assoc(p, ^key), as: ^key)

      if is_list(values) do
        add_join(key, values, acc)
      end
    end)
  end

  defp add_join(root, values, acc) when is_list(values) do
    Enum.reduce(values, acc, fn assoc, acc ->
      add_join(root, assoc, acc)
    end)
  end

  defp add_join(root, key, acc) when is_atom(key) do
    binding = "#{root}_#{key}"
    join(acc, :inner, [{^root, p}], _ in assoc(p, ^key), as: ^binding)
  end

  defp add_join(root, {key, values}, acc) do
    binding = "#{root}_#{key}"
    acc = join(acc, :inner, [{^root, p}], _ in assoc(p, ^key), as: ^binding)

    add_join(binding, values, acc)
  end

  defp check_assoc_path(condition, acc) do
    assoc_path = condition.private[:association_path]

    if is_nil(assoc_path) do
      acc
    else
      assoc_path ++ acc
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

  defp format_response({:ok, conditions}, query), do: {:ok, query, conditions}
  defp format_response({:error, error}, query), do: {:error, query, error}
end
