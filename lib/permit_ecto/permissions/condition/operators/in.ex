defmodule Permit.Permissions.Operators.In.DynamicQuery do
  import Ecto.Query, only: [dynamic: 2]

  @spec dynamic_query_fn(term(), boolean()) :: (any() -> Ecto.Query.DynamicExpr.t()) | nil
  def dynamic_query_fn(key, not?) do
    if not? do
      &dynamic([r], field(r, ^key) not in ^&1)
    else
      &dynamic([r], field(r, ^key) in ^&1)
    end
  end
end
