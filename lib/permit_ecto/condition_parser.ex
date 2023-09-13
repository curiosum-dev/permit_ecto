defmodule Permit.Ecto.Permissions.ConditionParser do
  @moduledoc false
  alias Permit.Permissions.ConditionParser
  alias Permit.Permissions.ParsedCondition

  import Ecto.Query

  @behaviour Permit.Permissions.ConditionParserBase

  @impl true
  def build({semantics_fun, query_fun}, ops)
      when is_function(semantics_fun) and is_function(query_fun) do
    ConditionParser.build(semantics_fun, ops)
    |> put_query_function(query_fun)
  end

  def build(raw_condition, ops) do
    ConditionParser.build(raw_condition, ops)
    |> then(
      &%{
        &1
        | private:
            Map.put(&1.private, :dynamic_query_fn, parsed_condition_to_dynamic_query_fn(&1))
      }
    )
  end

  defp parsed_condition_to_dynamic_query_fn(%ParsedCondition{
         condition: function,
         condition_type: :function_1
       }) do
    fn _ ->
      {:error, {:condition_unconvertible, %{condition: function, type: :function_1}}}
    end
  end

  defp parsed_condition_to_dynamic_query_fn(%ParsedCondition{
         condition: function,
         condition_type: :function_2
       }) do
    fn _, _ ->
      {:error, {:condition_unconvertible, %{condition: function, type: :function_2}}}
    end
  end

  defp parsed_condition_to_dynamic_query_fn(%ParsedCondition{
         condition: condition,
         condition_type: :const
       }) do
    fn _ -> {:ok, dynamic(^condition)} end
  end

  defp parsed_condition_to_dynamic_query_fn(%ParsedCondition{
         condition: {key, _val_fn} = condition,
         condition_type: {:operator, module},
         not: not?
       }) do
    case Module.concat(module, DynamicQuery).dynamic_query_fn(key, not?) do
      nil ->
        fn _ ->
          {:error, {:condition_unconvertible, %{condition: condition, type: {:operator, module}}}}
        end

      query ->
        &{:ok, query.(&1)}
    end
  end

  defp put_query_function(%ParsedCondition{} = condition, query_fun) do
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
