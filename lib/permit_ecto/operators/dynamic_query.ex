defmodule Permit.Operators.DynamicQuery do
  @moduledoc """
  Implemented to define a dynamic query builder function for an operator, that is
  a module that implements `Permit.Operators.GenOperator`.

  For example, when an operator is defined in the `Permit.Operators.Eq` module, its
  dynamic query builder function should be defined in `Permit.Operators.Eq.DynamicQuery`.

  Part of the private API, subject to changes and not to be used on the application level.
  """
  @callback dynamic_query_fn(Permit.Types.struct_field(), boolean()) ::
              (any() -> %Ecto.Query.DynamicExpr{}) | nil
end
