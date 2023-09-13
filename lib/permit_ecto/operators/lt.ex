defmodule Permit.Operators.Lt.DynamicQuery do
  @moduledoc false
  import Ecto.Query, only: [dynamic: 2]

  @behaviour Permit.Operators.DynamicQuery

  @impl true
  def dynamic_query_fn(key, not?) do
    if not? do
      &dynamic([r], field(r, ^key) >= ^&1)
    else
      &dynamic([r], field(r, ^key) < ^&1)
    end
  end
end
