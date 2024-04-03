defmodule Permit.Ecto.Permissions.ConditionParser do
  @moduledoc false
  alias Permit.Permissions.ConditionParser
  alias Permit.Permissions.ParsedCondition

  import Ecto.Query

  @behaviour Permit.Permissions.ConditionParserBase

  @impl true
  def build({semantics_fun, query_fun}, ops)
      when is_function(semantics_fun) and is_function(query_fun) do
    semantics_fun
    |> ConditionParser.build(ops)
    |> put_query_function(query_fun)
  end

  def build(raw_condition, ops) do
    ConditionParser.build(raw_condition, ops)
    |> then(
      &%{
        &1
        | private:
            Map.merge(&1.private, %{
              association_path: build_assoc_path(raw_condition),
              dynamic_query_fn: parsed_condition_to_dynamic_query_fn(&1)
            })
      }
    )
  end

  def build_assoc_path({key, values}) when is_list(values) do
    assocs =
      Enum.reduce(values, [], fn {k, v}, acc ->
        if is_list(v) do
          res = add_assoc(k, v, acc)

          acc ++ res
        else
          acc
        end
      end)

    [{key, assocs}]
  end

  def build_assoc_path(_conditions) do
    nil
  end

  defp add_assoc(root, values, _acc) do
    acc = [root]

    Enum.reduce(values, acc, fn {k, v}, acc ->
      if is_list(v) do
        acc = List.delete(acc, root)

        acc =
          if Enum.empty?(acc) do
            [{root, [k]}]
          else
            data = [k | get_in(acc, [root])]
            [{root, data}]
          end

        add_assoc([root], k, v, acc)
      else
        acc
      end
    end)
  end

  defp add_assoc(root, key, values, acc) do
    Enum.reduce(values, acc, fn {k, v}, acc ->
      if is_list(v) do
        x = get_in(acc, [key | root] |> Enum.reverse())

        if is_nil(x) do
          y = get_in(acc, root |> Enum.reverse()) |> List.delete(key)

          data =
            if Enum.empty?(y) do
              [{key, [k]}]
            else
              y
              |> List.delete(key)
              |> then(&[{key, [k]} | &1])
            end

          acc = put_in(acc, root |> Enum.reverse(), data)

          add_assoc([key | root], k, v, acc)
        else
          data = [k | get_in(acc, [key | root] |> Enum.reverse())]

          acc = put_in(acc, [key | root] |> Enum.reverse(), data)

          add_assoc([key | root], k, v, acc)
        end
      else
        acc
      end
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
