defmodule Permit.Ecto.Permissions.ParsedCondition do
  @moduledoc """
  Represents the product of parsing a condition by a function implementing
  the `c:Permit.Permissions.can/1` callback.

  Replaces `Permit.Permissions.ParsedCondition` in applications using `Permit.Ecto`.
  Refer to `Permit.Permissions.ParsedCondition` documentation for more details.

  In addition to the original implementation, its metadata also includes
  dynamic query constructors, derived from `Permit.Operators.DynamicQuery`.

  A condition parsed by Permit's rule syntax parser contains:
  * condition semantics, that is: a function that allows for checking
    whether the condition is satisfied
  * an indication of whether it is negated (i.e. a condition defined as
    `{:not, ...}`)
  * metadata (`:private`), which can be used by alternative parsers (e.g.
    `Permit.Ecto.Permissions` puts dynamic query constructors there)

  Part of the private API, subject to changes and not to be used on the
  application level.
  """

  import Ecto.Query, only: [dynamic: 1]

  alias Permit.Permissions.ParsedCondition
  alias Permit.Types

  @type dynamic_query :: (struct(), struct() -> Ecto.Query.t())

  @spec to_dynamic_query(ParsedCondition.t(), Types.object_or_resource_module(), Types.subject()) ::
          {:ok, Ecto.Query.dynamic()} | {:error, term()}
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
