defmodule Permit.Ecto.Types do
  @moduledoc """
  Defines Ecto-specific types for usage with Permit.
  """

  alias Permit.Types, as: OriginalTypes

  @typedoc """
  Allows defining a base Ecto query based on current resolution context, e.g. query
  parameters, request URL or anything else (depending on execution context).
  """
  @type base_query ::
          (OriginalTypes.resolution_context() -> Ecto.Query.t())

  @typedoc """
  Allows manipulating the query after it has been constructed by Permit's query builder,
  but before it is executed by `Permit.Ecto.Resolver`.
  """
  @type finalize_query ::
          (Ecto.Query.t(), OriginalTypes.resolution_context() -> Ecto.Query.t())
end
