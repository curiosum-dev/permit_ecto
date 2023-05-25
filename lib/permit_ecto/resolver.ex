defmodule Permit.Ecto.Resolver do
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
          true ->
            :unauthorized

          false ->
            raise Ecto.NoResultsError,
              queryable: base_query.(action, resource_module, subject, meta["params"])
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
           base_query: base_query,
           finalize_query: finalize_query,
           params: params
         } = _meta
       ) do
    subject
    |> authorization_module.accessible_by!(action, resource_module,
      base_query: base_query,
      params: params
    )
    |> finalize_query.()
  end

  defp ensure_meta_defaults(meta) do
    meta
    |> Map.put_new(:base_query, fn _action, resource_module, _subject, _params ->
      Ecto.Query.from(_ in resource_module)
    end)
    # |> Map.put_new(:finalize_query, &Function.identity/1)
    |> Map.put_new(:finalize_query, fn query, _action, _resource_module, _subject, _params ->
      query
    end)
  end

  defp check_existence(authorization_module, resource, base_query, action, subject, meta) do
    with module <- resource_module_from_resource(resource),
         query <- base_query.(action, module, subject, meta[:params]) do
      authorization_module.repo.exists?(query)
    end
  end
end
