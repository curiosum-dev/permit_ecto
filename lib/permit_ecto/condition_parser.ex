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
      association_path: build_assoc_path(raw_condition) |> List.wrap(),
      dynamic_query_fn: parsed_condition_to_dynamic_query_fn(parsed_condition)
    }

    %{parsed_condition | private: private}
  end

  def build_assoc_path(values) when is_list(values) do
    values
    |> Enum.reduce([], fn item, acc ->
      case build_assoc_path(item) do
        nil -> acc
        {atom, []} -> [atom | acc]
        not_nil -> [not_nil | acc]
      end
    end)
  end

  def build_assoc_path({key, values}) when is_list(values) do
    {key, build_assoc_path(values)}
  end

  def build_assoc_path(_conditions), do: nil

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
