defmodule Permit.Ecto.Resolver do
  @moduledoc """
  Implementation of `Permit.ResolverBase` behaviour, resolving and checks authorization of records or lists of records based on automatic Ecto query construction, taking parameters as input and `:base_query` and `:finalize_query` functions as means to transform the query based on e.g. current controller context.

  For a resolver implementation not using Ecto for fetching resources, see `Permit.Resolver` from the `permit` library.

  The usage of `Permit.Ecto.Resolver` as opposed to `Permit.Resolver` in `permit_ecto` library occurs because in the `m:Permit.Ecto.__using__/1` macro the `resolver_module/0` function is overridden to point to `Permit.Ecto.Resolver`.

  This module is to be considered a private API of the authorization framework.
  It should not be directly used by application code, but rather by wrappers
  providing integration with e.g. Plug or LiveView.
  """
  use Permit.ResolverBase

  require Ecto.Query

  import Permit.Helpers, only: [resource_module_from_resource: 1]

  @impl Permit.ResolverBase
  def resolve(subject, authorization_module, resource_module, action, %{} = meta, :one) do
    %{base_query: base_query} = meta = ensure_meta_defaults(meta)

    with {_, true} <-
           {:pre_auth, authorized?(subject, authorization_module, resource_module, action)},
         query <- resource_query(subject, authorization_module, resource_module, action, meta),
         resource when not is_nil(resource) <- authorization_module.repo().one(query),
         {_, true} <- {:auth, authorized?(subject, authorization_module, resource, action)} do
      {:authorized, resource}
    else
      {:pre_auth, false} ->
        :unauthorized

      {:auth, false} ->
        :unauthorized

      nil ->
        case check_existence(
               authorization_module,
               resource_module,
               base_query,
               action,
               subject,
               meta
             ) do
          {true, _} -> :unauthorized
          {false, query} -> raise Ecto.NoResultsError, queryable: query
        end
    end
  end

  @impl Permit.ResolverBase
  def resolve(subject, authorization_module, resource_module, action, %{} = meta, :all) do
    meta = ensure_meta_defaults(meta)

    with {_, true} <-
           {:pre_auth, authorized?(subject, authorization_module, resource_module, action)},
         query <- resource_query(subject, authorization_module, resource_module, action, meta),
         list <- authorization_module.repo().all(query) do
      {:authorized, list}
    else
      {:pre_auth, false} -> :unauthorized
    end
  end

  defp resource_query(
         subject,
         authorization_module,
         resource_module,
         action,
         %{finalize_query: finalize_query} = meta
       ) do
    subject
    |> authorization_module.accessible_by!(action, resource_module, meta)
    |> finalize_query.(meta)
  end

  defp ensure_meta_defaults(meta) do
    meta
    |> Map.put_new(:base_query, fn %{resource_module: resource_module} ->
      Ecto.Query.from(_ in resource_module)
    end)
    |> Map.put_new(:finalize_query, fn query, %{} ->
      query
    end)
  end

  defp check_existence(authorization_module, resource, base_query, action, subject, meta) do
    with module <- resource_module_from_resource(resource),
         resolution_context <-
           Map.merge(%{action: action, resource_module: module, subject: subject}, meta),
         query <- base_query.(resolution_context) do
      {authorization_module.repo.exists?(query), query}
    end
  end
end
