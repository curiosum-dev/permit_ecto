defmodule Permit.Ecto.EctoParsedCondition do
  import Ecto.Query, only: [dynamic: 1]

  alias Permit.Types
  alias Permit.Permissions.ParsedCondition

  @type dynamic_query :: (struct(), struct() -> Ecto.Query.t())

  @spec to_dynamic_query(ParsedCondition.t(), Types.resource(), Types.subject()) ::
          {:ok, Ecto.Query.DynamicExpr.t()} | {:error, term()}
  def to_dynamic_query(
        %ParsedCondition{condition: {_key, val_fn}, private: %{dynamic_query_fn: query_fn}},
        subject,
        resource
      ),
      do: val_fn.(subject, resource) |> query_fn.()

  def to_dynamic_query(%ParsedCondition{condition: condition, condition_type: :const}, _, _),
    do: {:ok, dynamic(^condition)}

  def to_dynamic_query(
        %ParsedCondition{condition_type: :function_2, private: %{dynamic_query_fn: query_fn}},
        subject,
        resource
      ) do
    query_fn.(subject, resource)
  end

  def to_dynamic_query(
        %ParsedCondition{condition_type: :function_1, private: %{dynamic_query_fn: query_fn}},
        _subject,
        resource
      ),
      do: query_fn.(resource)
end
