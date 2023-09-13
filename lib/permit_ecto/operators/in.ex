defmodule Permit.Operators.In.DynamicQuery do
  @moduledoc false
  import Ecto.Query, only: [dynamic: 2]

  @behaviour Permit.Operators.DynamicQuery

  @impl true
  def dynamic_query_fn(key, not?) do
    if not? do
      &dynamic([r], field(r, ^key) not in ^&1)
    else
      &dynamic([r], field(r, ^key) in ^&1)
    end
  end
end
