defmodule Permit.Permissions.QueryConstructionTest.Resource do
  use Ecto.Schema

  schema "test_objects" do
    field(:name, :string)
    field(:foo, :integer)
    field(:bar, :integer)
  end
end

defmodule Permit.Permissions.QueryConstructionTest do
  use ExUnit.Case, async: true
  alias Permit.Permissions
  alias Permit.Ecto.Permissions, as: EctoPermissions
  alias Permit.Permissions.QueryConstructionTest.Resource
  import Ecto.Query

  def sigil_q(conditions, []) do
    conditions
    |> Code.eval_string()
    |> elem(0)
    |> Enum.map(fn raw_condition ->
      Permit.Permissions.parse_condition(
        raw_condition,
        [],
        &Permit.Ecto.Permissions.ConditionParser.build/2
      )
    end)
  end

  setup do
    resource = %Resource{foo: 1, bar: 2, name: "name"}

    query_convertible =
      Permissions.new()
      |> Permissions.add(:delete, Resource, ~q/[foo: {:>=, 0}, bar: {{:not, :==}, 5}]/)
      |> Permissions.add(:delete, Resource, ~q/[name: nil, bar: {:not, nil}]/)
      |> Permissions.add(:update, Resource, ~q/[name: {:ilike, "%NAME"}]/)
      |> Permissions.add(:read, Resource, ~q/[foo: {:eq, 1}, name: {:not, nil}]/)
      |> Permissions.add(:create, Resource, ~q/[name: {:like, "%"}, foo: nil]/)

    query_convertible_function =
      Permissions.new()
      |> Permissions.add(:delete, Resource, ~q/[
        (require Ecto.Query) &&
        {fn _subject, object -> object.foo == 1 end,
         fn _subject, _object ->
           Ecto.Query.dynamic([o], o.foo == 1)
         end}
      ]/)

    query_convertible_nil =
      Permissions.new()
      |> Permissions.add(:delete, Resource, ~q/[foo: {:!=, nil}, bar: {{:not, :==}, nil}]/)
      |> Permissions.add(:delete, Resource, ~q/[name: nil, bar: {:not, nil}]/)
      |> Permissions.add(:update, Resource, ~q/[name: {:eq, nil}]/)
      |> Permissions.add(:read, Resource, ~q/[foo: {{:not, :eq}, nil}, name: {:not, nil}]/)
      |> Permissions.add(:create, Resource, ~q/[name: {:like, "%"}, foo: nil]/)

    query_nonconvertible =
      Permissions.new()
      |> Permissions.add(:delete, Resource, ~q/[fn _subj, res -> res.foo == 1 end]/)
      |> Permissions.add(:update, Resource, ~q'[name: {:=~, ~r/name/i}]')
      |> Permissions.add(:read, Resource, ~q/[fn res -> res.foo > 0 and res.bar < 100 end]/)
      |> Permissions.add(:create, Resource, ~q/[fn res -> res.foo * res.bar < 10 or true end]/)

    %{
      resource: resource,
      convertible: query_convertible,
      convertible_nil: query_convertible_nil,
      convertible_function: query_convertible_function,
      nonconvertible: query_nonconvertible,
      actions_module: Permit.Actions.CrudActions,
      subject: nil
    }
  end

  describe "Permit.Ecto.Permissions.construct_query/3" do
    test "should construct query", %{
      resource: res,
      convertible_nil: permissions,
      actions_module: module,
      subject: subject
    } do
      assert {:ok, _query} =
               EctoPermissions.construct_query(permissions, :delete, res, subject, module)

      assert {:ok, _query} =
               EctoPermissions.construct_query(permissions, :create, res, subject, module)

      assert {:ok, _query} =
               EctoPermissions.construct_query(permissions, :read, res, subject, module)

      assert {:ok, _query} =
               EctoPermissions.construct_query(permissions, :update, res, subject, module)
    end

    test "should construct query for permissions defined with functions", %{
      resource: res,
      convertible_function: permissions,
      actions_module: module,
      subject: subject
    } do
      assert {:ok, _query} =
               EctoPermissions.construct_query(permissions, :delete, res, subject, module)
    end

    test "should not construct ecto query", %{
      resource: res,
      nonconvertible: permissions,
      actions_module: module,
      subject: subject
    } do
      assert {:error, condition_unconvertible: %{type: :function_2}} =
               EctoPermissions.construct_query(permissions, :delete, res, subject, module)

      assert {:error, condition_unconvertible: _} =
               EctoPermissions.construct_query(permissions, :update, res, subject, module)

      assert {:error, condition_unconvertible: %{type: :function_1}} =
               EctoPermissions.construct_query(permissions, :read, res, subject, module)

      assert {:error, condition_unconvertible: %{type: :function_1}} =
               EctoPermissions.construct_query(permissions, :create, res, subject, module)
    end

    test "should construct proper query with or", %{
      resource: res,
      convertible: permissions,
      actions_module: module,
      subject: subject
    } do
      {:ok, query} = EctoPermissions.construct_query(permissions, :delete, res, subject, module)

      assert compare_query(
               query,
               from(r in res.__struct__,
                 where:
                   (is_nil(r.name) and not is_nil(r.bar)) or
                     (r.foo >= ^0 and r.bar != ^5)
               )
             )
    end

    test "should construct proper query with like operator", %{
      resource: res,
      convertible: permissions,
      actions_module: module,
      subject: subject
    } do
      {:ok, query} = EctoPermissions.construct_query(permissions, :update, res, subject, module)

      assert compare_query(
               query,
               from(r in res.__struct__,
                 where: ilike(r.name, ^"%NAME")
               )
             )
    end

    test "should construct proper query with eq and not nil", %{
      resource: res,
      convertible: permissions,
      actions_module: module,
      subject: subject
    } do
      {:ok, query} = EctoPermissions.construct_query(permissions, :read, res, subject, module)

      assert compare_query(
               query,
               from(r in res.__struct__,
                 where: r.foo == ^1 and not is_nil(r.name)
               )
             )
    end

    test "should construct proper query with nil", %{
      resource: res,
      convertible: permissions,
      actions_module: module,
      subject: subject
    } do
      {:ok, query} = EctoPermissions.construct_query(permissions, :create, res, subject, module)

      assert compare_query(
               query,
               from(r in res.__struct__,
                 where: like(r.name, ^"%") and is_nil(r.foo)
               )
             )
    end
  end

  defp compare_query(
         %Ecto.Query{from: from, wheres: [%{expr: expr, op: op, params: params}]},
         %Ecto.Query{from: from, wheres: [%{expr: expr, op: op, params: params}]}
       ),
       do: true

  defp compare_query(_, _), do: false
end
