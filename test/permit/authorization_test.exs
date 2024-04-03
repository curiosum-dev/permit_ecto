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

  describe "ecto query construction" do
    test "should construct ecto query" do
      assert {:ok, query1} = TestAuthorization.accessible_by(@like_role, :delete, TestObject)

      assert where1 =
               query1.wheres
               |> Enum.find(
                 &(&1.params
                   |> Enum.find(fn {pattern, _} -> pattern == "%!!%!%%!_%" end))
               )

      assert {:like, _, _} = where1.expr

      assert {:ok, query2} = TestAuthorization.accessible_by(@like_role, :create, TestObject)

      assert where2 =
               query2.wheres
               |> Enum.find(
                 &(&1.params
                   |> Enum.find(fn {pattern, _} -> pattern == "spe__a_" end))
               )

      assert {:like, _, _} = where2.expr

      assert {:ok, query3} = TestAuthorization.accessible_by(@like_role, :read, TestObject)

      assert where3 =
               query3.wheres
               |> Enum.find(
                 &(&1.params
                   |> Enum.find(fn {pattern, _} -> pattern == "%xcEpt%" end))
               )

      assert {:ilike, _, _} = where3.expr

      assert {:ok, query4} = TestAuthorization.accessible_by(@like_role, :update, TestObject)

      assert where4 =
               query4.wheres
               |> Enum.find(
                 &(&1.params
                   |> Enum.find(fn {pattern, _} -> pattern == "speci!%" end))
               )

      assert {:not, [], [{:like, _, _}]} = where4.expr
    end

    test "should not construct ecto query" do
      assert {:error, _q, condition_unconvertible: _, condition_unconvertible: _} =
               TestAuthorization.accessible_by(@another_one_role, :delete, TestObject)

      assert {:error, _q, condition_unconvertible: %{type: :function_2}} =
               TestAuthorization.accessible_by(@manager_role, :delete, TestObject)
    end
  end
end
