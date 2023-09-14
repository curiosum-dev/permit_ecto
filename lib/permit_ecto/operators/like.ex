defmodule Permit.Operators.Like.DynamicQuery do
  @moduledoc false
  import Ecto.Query, only: [dynamic: 2]

  @behaviour Permit.Operators.DynamicQuery

  @impl true
  def dynamic_query_fn(key, not?) do
    if not? do
      &dynamic([r], not like(field(r, ^key), ^&1))
    else
      &dynamic([r], like(field(r, ^key), ^&1))
    end
  end
end
