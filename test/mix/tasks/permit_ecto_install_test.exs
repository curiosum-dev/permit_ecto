if Version.match?(System.version(), ">= 1.15.0") and Code.ensure_loaded?(Igniter.Test) do
  defmodule Mix.Tasks.PermitEcto.InstallTest do
    use ExUnit.Case

    import Igniter.Test

  describe "permit_ecto.install" do
    test "creates authorization and permissions modules" do
      test_project()
      |> Igniter.compose_task("permit_ecto.install", [])
      |> assert_creates("lib/test/authorization.ex")
      |> assert_creates("lib/test/authorization/permissions.ex")
    end

    test "authorization module uses Permit.Ecto with correct options" do
      igniter =
        test_project()
        |> Igniter.compose_task("permit_ecto.install", [])
        |> apply_igniter!()

      source = Rewrite.source!(igniter.rewrite, "lib/test/authorization.ex")
      content = Rewrite.Source.get(source, :content)

      assert content =~ "use Permit.Ecto"
      assert content =~ "permissions_module: Test.Authorization.Permissions"
      assert content =~ "repo: Test.Repo"
    end

    test "permissions module uses Permit.Ecto.Permissions with CrudActions by default" do
      igniter =
        test_project()
        |> Igniter.compose_task("permit_ecto.install", [])
        |> apply_igniter!()

      source = Rewrite.source!(igniter.rewrite, "lib/test/authorization/permissions.ex")
      content = Rewrite.Source.get(source, :content)

      assert content =~ "use Permit.Ecto.Permissions, actions_module: Permit.Actions.CrudActions"
      assert content =~ "def can(_user) do"
      assert content =~ "permit()"
    end

    test "uses custom repo when specified" do
      igniter =
        test_project()
        |> Igniter.compose_task("permit_ecto.install", ["--repo", "Test.CustomRepo"])
        |> apply_igniter!()

      source = Rewrite.source!(igniter.rewrite, "lib/test/authorization.ex")
      content = Rewrite.Source.get(source, :content)

      assert content =~ "repo: Test.CustomRepo"
    end

    test "uses provided actions module in permissions" do
      igniter =
        test_project()
        |> Igniter.compose_task("permit_ecto.install", [
          "--actions-module",
          "Test.Authorization.Actions"
        ])
        |> apply_igniter!()

      source = Rewrite.source!(igniter.rewrite, "lib/test/authorization/permissions.ex")
      content = Rewrite.Source.get(source, :content)

      assert content =~ "actions_module: Test.Authorization.Actions"
    end

    test "uses custom authorization module name" do
      test_project()
      |> Igniter.compose_task("permit_ecto.install", [
        "--authorization-module",
        "Test.Auth"
      ])
      |> assert_creates("lib/test/auth.ex")
    end

    test "uses custom permissions module name" do
      test_project()
      |> Igniter.compose_task("permit_ecto.install", [
        "--authorization-module",
        "Test.Auth",
        "--permissions-module",
        "Test.Auth.Perms"
      ])
      |> assert_creates("lib/test/auth.ex")
      |> assert_creates("lib/test/auth/perms.ex")
    end
  end
  end
end
