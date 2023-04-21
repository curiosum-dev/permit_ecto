defmodule Permit.Ecto.RuleSyntax do
  # defmacro __using__(opts) do
  #   quote do
  #     use Permit.RuleSyntax, unquote(opts)

  #     # TODO: Figure out how to really override it, the parent module no longer mixes it in in __using__...
  #     def parse_condition(condition, bindings) do
  #       condition
  #       |> Permit.Ecto.EctoParsedCondition.build(bindings: bindings)
  #     end
  #   end
  # end
  import Ecto.Query

  # alias Permit.Permissions.Operators
  alias Permit.Permissions.ParsedCondition

  def decorate_condition(parsed_condition) do
    %{
      parsed_condition
      | private:
          Map.put(
            parsed_condition.private,
            :dynamic_query_fn,
            parsed_condition_to_dynamic_query_fn(parsed_condition)
          )
    }
  end

  defmacro __using__(opts) do
    opts = Keyword.put(opts, :condition_decorator, &Permit.Ecto.RuleSyntax.decorate_condition/1)

    quote do
      use Permit.RuleSyntax, unquote(opts)

      import Permit.Ecto.RuleSyntax
    end
  end

  # @impl true
  # def parse_condition(raw_condition, bindings) do
  #   pc =
  #     raw_condition
  #     |> Permit.Permissions.ParsedCondition.build(bindings: bindings)

  #   %{
  #     pc
  #     | private: Map.put(pc.private, :dynamic_query_fn, parsed_condition_to_dynamic_query_fn(pc))
  #   }
  # end

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
end
