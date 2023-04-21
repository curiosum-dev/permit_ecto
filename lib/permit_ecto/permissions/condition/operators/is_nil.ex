defmodule Permit.Permissions.Operators.IsNil.DynamicQuery do
  import Ecto.Query, only: [dynamic: 2]

  @spec dynamic_query_fn(term(), keyword()) :: (any() -> Ecto.Query.DynamicExpr.t()) | nil
  def dynamic_query_fn(key, not?) do
    if not? do
      fn _ -> dynamic([r], not is_nil(field(r, ^key))) end
    else
      fn _ -> dynamic([r], is_nil(field(r, ^key))) end
    end
  end
end
