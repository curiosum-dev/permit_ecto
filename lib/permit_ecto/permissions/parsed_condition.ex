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
          {:ok, Ecto.Query.dynamic()} | {:error, term()}

  def to_dynamic_query(
        %ParsedCondition{
          condition: {key, val_fn},
          condition_type: {:association, _}
        },
        subject,
        resource,
        q
      ) do
    conditions =
      if is_function(val_fn) do
        val_fn.(subject, resource)
      else
        val_fn
      end

    condition = build_dynamic_query({key, conditions}, q)

    {:ok, condition}
  end

  def to_dynamic_query(
        %ParsedCondition{condition: {_key, val_fn}, private: %{dynamic_query_fn: query_fn}},
        subject,
        resource,
        _q
      ),
      do: val_fn.(subject, resource) |> query_fn.()

  def to_dynamic_query(%ParsedCondition{condition: condition, condition_type: :const}, _, _, _q),
    do: {:ok, dynamic(^condition)}

  def to_dynamic_query(
        %ParsedCondition{condition_type: :function_2, private: %{dynamic_query_fn: query_fn}},
        subject,
        resource,
        _q
      ) do
    query_fn.(subject, resource)
  end

  def to_dynamic_query(
        %ParsedCondition{condition_type: :function_1, private: %{dynamic_query_fn: query_fn}},
        _subject,
        resource,
        _q
      ),
      do: query_fn.(resource)

  defp build_dynamic_query({root, conditions}, q) do
    conditions
    |> Enum.reduce(dynamic(true), fn {field, value}, acc ->
      if Keyword.keyword?(value) do
        Enum.reduce(value, acc, fn {k, v}, acc ->
          add_condition(root, field, {k, v}, acc, q)
        end)
      else
        n = Map.get(q.aliases, root)

        dynamic([{x, n}], ^acc and field(x, ^field) == ^value)
      end
    end)
  end

  defp add_condition(root, field, {key, v}, acc, q) when is_list(v) do
    binding =
      if root == field do
        "#{field}_#{key}"
      else
        "#{root}_#{field}_#{key}"
      end

    Enum.reduce(v, acc, fn {k, v}, acc ->
      add_condition(root, key, binding, {k, v}, acc, q)
    end)
  end

  defp add_condition(root, field, {k, v}, acc, q) do
    binding =
      if root == field do
        root
      else
        if String.starts_with?(to_string(field), to_string(root)) do
          field
        else
          "#{root}_#{field}"
        end
      end

    n = Map.get(q.aliases, binding)
    dynamic([{y, n}], ^acc and field(y, ^k) == ^v)
  end

  defp add_condition(root, _field, binding, {k, v}, acc, q) when is_list(v) do
    binding = "#{binding}_#{k}"

    Enum.reduce(v, acc, fn {k, v}, acc ->
      add_condition(root, binding, {k, v}, acc, q)
    end)
  end

  defp add_condition(_root, field, binding, {k, v}, acc, q) do
    {_binding_name, n} =
      Enum.find(q.aliases, fn {x, _y} ->
        case x do
          x when is_binary(x) -> String.ends_with?(x, binding)
          x when is_atom(x) -> x == field
        end
      end)

    dynamic([{y, n}], ^acc and field(y, ^k) == ^v)
  end
end
