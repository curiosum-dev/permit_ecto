defmodule Permit.Ecto.Permissions.ParsedCondition do
  @moduledoc """
  Represents the product of parsing a condition by a function implementing
  the `c:Permit.Permissions.can/1` callback.

  Replaces `Permit.Permissions.ParsedCondition` in applications using `Permit.Ecto`.
  Refer to `Permit.Permissions.ParsedCondition` documentation for more details.

  In add_conditionition to the original implementation, its metadata also includes
  dynamic query constructors, derived from `Permit.Operators.DynamicQuery`.

  A condition parsed by Permit's rule syntax parser contains:
  * condition semantics, that is: a function that allows for checking
    whether the condition is satisfied
  * an indication of whether it is negated (i.e. a condition defined as
    `{:not, ...}`)
  * metadata (`:private`), which can be used by alternative parsers (e.g.
    `Permit.Ecto.Permissions` puts dynamic query constructors there)

  Part of the private API, subject to changes and not to be used on the
  application level.
  """

  import Ecto.Query

  alias Permit.Permissions.ParsedCondition
  alias Permit.Types

  @type dynamic_query :: (struct(), struct() -> Ecto.Query.t())

  @spec to_dynamic_query(
          ParsedCondition.t(),
          Types.object_or_resource_module(),
          Types.subject(),
          Ecto.Query.t()
        ) ::
          {:ok, Ecto.Query.dynamic_expr()} | {:error, term()}

  def to_dynamic_query(
        %ParsedCondition{
          condition: {key, val_fn},
          condition_type: {:association, _}
        },
        subject,
        resource,
        query
      ) do
    conditions =
      if is_function(val_fn) do
        val_fn.(subject, resource)
      else
        val_fn
      end

    condition = build_dynamic_query({key, conditions}, query)

    {:ok, condition}
  end

  def to_dynamic_query(
        %ParsedCondition{
          condition: {_key, val_fn},
          private: %{dynamic_query_fn: query_fn}
        },
        subject,
        resource,
        _query
      ),
      do: val_fn.(subject, resource) |> query_fn.()

  def to_dynamic_query(
        %ParsedCondition{condition: condition, condition_type: :const},
        _subject,
        _resource,
        _query
      ),
      do: {:ok, dynamic(^condition)}

  def to_dynamic_query(
        %ParsedCondition{
          condition_type: :function_2,
          private: %{dynamic_query_fn: query_fn}
        },
        subject,
        resource,
        _query
      ) do
    query_fn.(subject, resource)
  end

  def to_dynamic_query(
        %ParsedCondition{
          condition_type: :function_1,
          private: %{dynamic_query_fn: query_fn}
        },
        _subject,
        resource,
        _query
      ),
      do: query_fn.(resource)

  defp build_dynamic_query({root, conditions}, query) do
    Enum.reduce(
      conditions,
      dynamic(true),
      fn {field, value}, acc ->
        add_conditions(root, field, value, acc, query)
      end
    )
  end

  defp add_conditions(root, field, keyword_or_value, acc, query) do
    if Keyword.keyword?(keyword_or_value) do
      Enum.reduce(keyword_or_value, acc, fn {k, v}, acc ->
        add_condition(root, field, {k, v}, acc, query)
      end)
    else
      add_single_condition(root, field, keyword_or_value, acc, query)
    end
  end

  defp add_condition(root, field, {key, v}, acc, query) when is_list(v) do
    binding = get_binding(root, field, key)

    Enum.reduce(v, acc, fn {k, v}, acc ->
      add_condition(root, key, binding, {k, v}, acc, query)
    end)
  end

  defp add_condition(root, field, {key, value}, acc, query) do
    binding = get_binding(root, field)

    add_single_condition(binding, key, value, acc, query)
  end

  defp add_condition(root, _field, binding, {key, values}, acc, query) when is_list(values) do
    Enum.reduce(values, acc, fn {k, v}, acc ->
      add_condition(root, "#{binding}_#{key}", {k, v}, acc, query)
    end)
  end

  defp add_condition(_root, field, binding, {_key, value}, acc, query) do
    add_single_condition(binding, field, value, acc, query)
  end

  defp add_single_condition(binding, field, value, acc, query) do
    n = Map.get(query.aliases, binding)

    dynamic([{x, n}], ^acc and field(x, ^field) == ^value)
  end

  defp get_binding(root, field) when root == field, do: field

  defp get_binding(root, field) do
    if String.starts_with?(to_string(field), to_string(root)) do
      field
    else
      "#{root}_#{field}"
    end
  end

  defp get_binding(root, field, key) do
    if root == field do
      "#{field}_#{key}"
    else
      "#{root}_#{field}_#{key}"
    end
  end
end
