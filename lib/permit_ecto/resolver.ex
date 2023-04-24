defmodule Permit.Ecto.Resolver do
  use Permit.ResolverBase

  require Ecto.Query

  import Permit.Helpers, only: [resource_module_from_resource: 1]

  @impl Permit.ResolverBase
  def resolve(subject, authorization_module, resource_module, action, %{} = meta, :one) do
    %{prefilter_query_fn: prefilter_query_fn} = meta = ensure_meta_defaults(meta)

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
               prefilter_query_fn,
               action,
               meta
             ) do
          true ->
            :unauthorized

          false ->
            raise Ecto.NoResultsError,
              queryable: prefilter_query_fn.(action, resource_module, meta["params"])
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
         %{
           prefilter_query_fn: prefilter_query_fn,
           postfilter_query_fn: postfilter_query_fn,
           params: params
         } = _meta
       ) do
    subject
    |> authorization_module.accessible_by!(action, resource_module,
      prefilter: prefilter_query_fn,
      params: params
    )
    |> postfilter_query_fn.()
  end

  defp ensure_meta_defaults(meta) do
    meta
    |> Map.put_new(:prefilter_query_fn, fn _action, resource_module, _params ->
      Ecto.Query.from(_ in resource_module)
    end)
    |> Map.put_new(:postfilter_query_fn, & &1)
  end

  defp check_existence(authorization_module, resource, prefilter_query_fn, action, meta) do
    with module <- resource_module_from_resource(resource),
         query <- prefilter_query_fn.(action, module, meta[:params]) do
      authorization_module.repo.exists?(query)
    end
  end
end
