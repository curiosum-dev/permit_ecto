if Version.match?(System.version(), ">= 1.15.0") and Code.ensure_loaded?(Igniter) do
  defmodule Mix.Tasks.PermitEcto.Install do
    @shortdoc "Installs Permit.Ecto authorization into your project"

    @moduledoc """
    Installs Permit.Ecto authorization into your project, creating an authorization
    module and a permissions module configured for Ecto.

    ## Usage

        mix permit_ecto.install

    ## Options

    - `--authorization-module` - Authorization module name (default: `<MyApp>.Authorization`)
    - `--permissions-module` - Permissions module name (default: `<MyApp>.Authorization.Permissions`)
    - `--actions-module` - Actions module to use in permissions (default: `Permit.Actions.CrudActions`)
    - `--repo` - Ecto repo module name (auto-detected if not specified)
    """

    use Igniter.Mix.Task

    alias Igniter.Project.Module, as: ProjectModule

    @impl Igniter.Mix.Task
    def info(_argv, _composing_task) do
      %Igniter.Mix.Task.Info{
        group: :permit,
        schema: [
          authorization_module: :string,
          permissions_module: :string,
          actions_module: :string,
          repo: :string
        ]
      }
    end

    @impl Igniter.Mix.Task
    def igniter(igniter) do
      options = igniter.args.options
      app_module = ProjectModule.module_name_prefix(igniter)

      authorization_module =
        parse_module(options[:authorization_module], Module.concat(app_module, Authorization))

      permissions_module =
        parse_module(
          options[:permissions_module],
          Module.concat(authorization_module, Permissions)
        )

      actions_module = parse_module(options[:actions_module], nil)

      {igniter, repo} = detect_repo(igniter, options[:repo])

      igniter
      |> create_authorization_module(authorization_module, permissions_module, repo)
      |> create_permissions_module(permissions_module, actions_module)
      |> Igniter.add_notice("""
      Permit.Ecto has been set up!

      Edit #{inspect(permissions_module)} to define your permission rules.

      Example:

          def can(%MyApp.User{id: user_id}) do
            permit()
            |> all(MyApp.Resource, owner_id: user_id)
            |> read(MyApp.Resource)
          end
      """)
    end

    defp create_authorization_module(igniter, authorization_module, permissions_module, repo) do
      ProjectModule.create_module(igniter, authorization_module, """
        use Permit.Ecto,
          permissions_module: #{inspect(permissions_module)},
          repo: #{inspect(repo)}
      """)
    end

    defp create_permissions_module(igniter, permissions_module, actions_module) do
      resolved_actions = actions_module || Permit.Actions.CrudActions

      ProjectModule.create_module(igniter, permissions_module, """
        use Permit.Ecto.Permissions, actions_module: #{inspect(resolved_actions)}

        def can(_user) do
          permit()
        end
      """)
    end

    defp detect_repo(igniter, repo_string) when is_binary(repo_string) do
      {igniter, parse_module(repo_string, nil)}
    end

    defp detect_repo(igniter, nil) do
      if Code.ensure_loaded?(Igniter.Libs.Ecto) do
        {igniter, repos} = Igniter.Libs.Ecto.list_repos(igniter)

        case repos do
          [repo] ->
            {igniter, repo}

          [repo | _rest] ->
            {Igniter.add_notice(
               igniter,
               "Multiple Ecto repos detected. Using #{inspect(repo)}. Pass --repo to specify a different one."
             ), repo}

          [] ->
            app_module = ProjectModule.module_name_prefix(igniter)
            fallback = Module.concat(app_module, Repo)

            {Igniter.add_notice(
               igniter,
               "Could not auto-detect Ecto repo. Using #{inspect(fallback)}. Pass --repo if this is incorrect."
             ), fallback}
        end
      else
        app_module = ProjectModule.module_name_prefix(igniter)
        fallback = Module.concat(app_module, Repo)
        {igniter, fallback}
      end
    end

    defp parse_module(nil, default), do: default

    defp parse_module(string, _default) when is_binary(string) do
      string
      |> String.split(".")
      |> Module.concat()
    end
  end
end
