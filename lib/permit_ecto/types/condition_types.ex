defmodule Permit.Ecto.Types.ConditionTypes do
  @moduledoc """
  Provides new types for usage with Ecto queries, as well as  replacements for
  types initially defined in `Permit.Types.ConditionTypes`.
  """

  alias Permit.Types, as: OriginalTypes
  alias Permit.Types.ConditionTypes, as: OriginalConditionTypes

  # Condition types
  @type fn1_condition_with_query ::
          {OriginalConditionTypes.fn1_condition(), (OriginalTypes.object() -> Ecto.Query.t())}
  @type fn2_condition_with_query ::
          {OriginalConditionTypes.fn2_condition(),
           (OriginalTypes.subject(), OriginalTypes.object() -> Ecto.Query.t())}

  @type condition ::
          OriginalConditionTypes.condition()
          | fn1_condition_with_query()
          | fn2_condition_with_query()

  @type condition_or_conditions :: condition() | [condition()]
end
