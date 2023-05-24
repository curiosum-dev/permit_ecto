defmodule Permit.Ecto.AuthorizationTest do
  @moduledoc false
  use Permit.Case

  alias Permit.AuthorizationTest.Types.TestObject

  defmodule TestAuthorization do
    @moduledoc false
    use Permit.Ecto,
      permissions_module: Permit.AuthorizationTest.TestPermissions
  end

  @manager_role :manager
  @another_one_role :another
  @like_role :like_tester

  @like_object %TestObject{name: "strange! name% with _ special characters"}

  describe "ecto query construction" do
    test "should construct ecto query" do
      assert {:ok, _query} = TestAuthorization.accessible_by(@like_role, :delete, @like_object)
      assert {:ok, _query} = TestAuthorization.accessible_by(@like_role, :create, @like_object)
      assert {:ok, _query} = TestAuthorization.accessible_by(@like_role, :read, @like_object)
      assert {:ok, _query} = TestAuthorization.accessible_by(@like_role, :update, @like_object)
    end

    test "should not construct ecto query" do
      assert {:error, condition_unconvertible: _, condition_unconvertible: _} =
               TestAuthorization.accessible_by(@another_one_role, :delete, @like_object)

      assert {:error, condition_unconvertible: %{type: :function_2}} =
               TestAuthorization.accessible_by(@manager_role, :delete, @like_object)
    end
  end
end
