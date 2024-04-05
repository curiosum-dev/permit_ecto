defmodule Permit.Ecto.Permissions.ConditionParser do
  @moduledoc false

  import Ecto.Query

  alias Permit.Permissions.ConditionParser
  alias Permit.Permissions.ParsedCondition

  @behaviour Permit.Permissions.ConditionParserBase

  @impl true
  def build({semantics_fun, query_fun}, ops)
      when is_function(semantics_fun) and is_function(query_fun) do
    semantics_fun
    |> ConditionParser.build(ops)
    |> put_query_function(query_fun)
  end

  def build(raw_condition, ops) do
    parsed_condition = ConditionParser.build(raw_condition, ops)

    private = %{
      association_path: build_assoc_path(raw_condition),
      dynamic_query_fn: parsed_condition_to_dynamic_query_fn(parsed_condition)
    }

    %{parsed_condition | private: private}
  end

  def build_assoc_path({key, values}) when is_list(values) do
    values
    |> Enum.reduce([], fn
      {key, values}, acc when is_list(values) ->
        acc ++ add_assoc(key, values, acc)

      _condition, acc ->
        acc
    end)
    |> then(&[{key, &1}])
  end

  def build_assoc_path(_conditions), do: nil

  defp add_assoc(root, values, _acc) do
    Enum.reduce(values, [root], fn
      {key, values}, acc when is_list(values) ->
        acc = List.delete(acc, root)

        acc =
          if Enum.empty?(acc) do
            [{root, [key]}]
          else
            data = [key | get_in(acc, [root])]
            [{root, data}]
          end

        add_assoc([root], key, values, acc)

      {_key, _value}, acc ->
        acc
    end)
  end

  defp add_assoc(root, key, values, acc) do
    Enum.reduce(values, acc, fn
      {sub_key, sub_values}, acc when is_list(sub_values) ->
        assoc_key_path = Enum.reverse([key | root])

        if is_nil(get_in(acc, assoc_key_path)) do
          sub_assocs =
            acc
            |> get_in(Enum.reverse(root))
            |> List.delete(key)

          updated_assocs =
            if Enum.empty?(sub_assocs) do
              [{key, [sub_key]}]
            else
              sub_assocs
              |> List.delete(key)
              |> then(&[{key, [sub_key]} | &1])
            end

          acc = put_in(acc, Enum.reverse(root), updated_assocs)

          add_assoc([key | root], sub_key, sub_values, acc)
        else
          updated_assocs = [sub_key | get_in(acc, assoc_key_path)]

          acc = put_in(acc, assoc_key_path, updated_assocs)

          add_assoc([key | root], sub_key, sub_values, acc)
        end

      {_sub_key, _sub_value}, acc ->
        acc
    end)
  end

  def parsed_condition_to_dynamic_query_fn(%ParsedCondition{
        condition: function,
        condition_type: :function_1
      }) do
    fn _ ->
      {:error, {:condition_unconvertible, %{condition: function, type: :function_1}}}
    end
  end

  def parsed_condition_to_dynamic_query_fn(%ParsedCondition{
        condition: function,
        condition_type: :function_2
      }) do
    fn _, _ ->
      {:error, {:condition_unconvertible, %{condition: function, type: :function_2}}}
    end
  end

  def parsed_condition_to_dynamic_query_fn(%ParsedCondition{
        condition: condition,
        condition_type: :const
      }) do
    fn _ -> {:ok, dynamic(^condition)} end
  end

  def parsed_condition_to_dynamic_query_fn(%ParsedCondition{
        condition: {key, _val_fn} = condition,
        condition_type: {type, module},
        not: not?
      })
      when type in [:operator, :association] do
    case Module.concat(module, DynamicQuery).dynamic_query_fn(key, not?) do
      nil ->
        fn _ ->
          {:error, {:condition_unconvertible, %{condition: condition, type: {:operator, module}}}}
        end

      query ->
        &{:ok, query.(&1)}
    end
  end

  def put_query_function(%ParsedCondition{} = condition, query_fun) do
    case query_fun do
      f when is_function(f, 2) ->
        %ParsedCondition{
          condition
          | private: Map.put(condition.private, :dynamic_query_fn, &{:ok, query_fun.(&1, &2)})
        }

      f when is_function(f, 1) ->
        %ParsedCondition{
          condition
          | private: Map.put(condition.private, :dynamic_query_fn, &{:ok, query_fun.(&1)})
        }
    end
  end
end
