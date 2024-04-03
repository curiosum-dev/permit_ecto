defmodule Permit.Permissions.QueryConstructionTest.User do
  defstruct [:id, :name, :class]
end

defmodule Permit.Permissions.QueryConstructionTest.Class do
  defstruct [:id, :name]
end

defmodule Permit.Permissions.QueryConstructionTest.Resource do
  use Ecto.Schema

  schema "test_objects" do
    field(:name, :string)
    field(:foo, :integer)
    field(:bar, :integer)
    belongs_to(:user, Permit.Permissions.QueryConstructionTest.User)
  end
end

defmodule Permit.Permissions.QueryConstructionTest do
  use ExUnit.Case, async: true
  alias Permit.Ecto.Permissions.Conjunction
  alias Permit.Permissions.ParsedConditionList
  alias Permit.Ecto.Permissions.ConditionParser
  alias Permit.Permissions
  alias Permit.Ecto.Permissions, as: EctoPermissions
  alias Permit.Permissions.QueryConstructionTest.{Resource}
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

    query_with_accosc =
      Permissions.new()
      |> Permissions.add(
        :delete,
        Resource,
        ~q/[user: [id: 2,class: [id: 1, type: [id: 1]],phone: [id: 1, num: 123],address: [id: 2, street: "test"]]]/
      )
      |> Permissions.add(:delete, Resource, ~q/[title: [id: 1, type: [name: "public"]]]/)
      |> Permissions.add(:delete, Resource, ~q/[name: "test"]/)

    %{
      resource: resource,
      convertible: query_convertible,
      convertible_nil: query_convertible_nil,
      convertible_function: query_convertible_function,
      nonconvertible: query_nonconvertible,
      actions_module: Permit.Actions.CrudActions,
      with_assocs: query_with_accosc,
      subject: nil
    }
  end

  describe "Permit.Ecto.Permissions.ConditionParser/1" do
    test "should build correct association path" do
      raw_condition =
        {:user,
         [
           id: 2,
           class: [id: 1, type: [id: 1]],
           phone: [id: 1, num: 123],
           address: [id: 2, street: "test"]
         ]}

      result = ConditionParser.build_assoc_path(raw_condition)

      assert result == [user: [{:class, [:type]}, :phone, :address]]

      raw_condition =
        {:account,
         [
           id: 2,
           name: "test",
           type: [
             id: 1,
             name: "money",
             sub_type: [
               id: 1,
               name: "test",
               address: [id: 1, street: [id: 1]],
               assoc: [id: 1]
             ]
           ],
           balance: [
             id: 1,
             amount: [id: 1],
             currency: [name: "USD"],
             test: [id: 1, test2: [test3: []]]
           ]
         ]}

      result = ConditionParser.build_assoc_path(raw_condition)

      assert result == [
               account: [
                 type: [sub_type: [:assoc, address: [:street]]],
                 balance: [{:test, [test2: [:test3]]}, :currency, :amount]
               ]
             ]

      raw_condition =
        {:book,
         [
           id: 1,
           user_2: [id: 1, class: [id: 2]],
           user_1: [id: 2, class: [id: 1], project: [id: 1, client: [id: 1, class: [id: 1]]]]
         ]}

      result = ConditionParser.build_assoc_path(raw_condition)

      assert result == [
               book: [{:user_2, [:class]}, {:user_1, [{:project, [client: [:class]]}, :class]}]
             ]
    end
  end

  describe "Permit.Ecto.Permissions.construct_query/3" do
    test "should return dynamic query" do
      val_fn_1 = fn _subject, _object ->
        [
          id: 1,
          name: "name",
          user: [
            id: 2,
            class: [id: 1, type: [id: 1]],
            phone: [id: 1, num: 123],
            address: [id: 2, street: "test"]
          ]
        ]
      end

      val_fn_2 = fn _subject, _object ->
        [
          id: 2,
          name: "test",
          type: [id: 1, name: "money", sub_type: [id: 1, name: "test", address: [id: 1]]],
          balance: [id: 1, amount: "111", currency: [name: "USD"]]
        ]
      end

      condition_1 = %Permit.Permissions.ParsedCondition{
        condition: {:user, val_fn_1},
        condition_type: {:association, ""},
        private: %{
          association_path: [user: [:phone, :address, class: [:type]]]
        }
      }

      condition_2 = %Permit.Permissions.ParsedCondition{
        condition: {:account, val_fn_2},
        condition_type: {:association, ""},
        private: %{
          association_path: [account: [type: [sub_type: [:address]], balance: [:currency]]]
        }
      }

      condition_3 = %Permit.Permissions.ParsedCondition{
        condition: {:title, fn _, _ -> 1 end},
        condition_type: {:operator, Permit.Operators.Eq},
        not: false,
        private: %{}
      }

      dynamic_query_fn = ConditionParser.parsed_condition_to_dynamic_query_fn(condition_3)

      condition_3 = Map.put(condition_3, :private, %{dynamic_query_fn: dynamic_query_fn})

      conditions = [
        account: [type: [sub_type: [:address]], balance: [:currency]],
        user: [:phone, :address, class: [:type]]
      ]

      resource = Resource

      q =
        Permit.Ecto.Permissions.DynamicQueryJoiner.add_joins(
          conditions,
          from(r in Resource, as: ^resource)
        )

      conditions = [condition_1, condition_2, condition_3]

      {:ok, result} =
        Conjunction.to_dynamic_query_expr(
          %ParsedConditionList{conditions: conditions},
          resource,
          %Resource{},
          q
        )

      assert q |> where(^result)
    end

    test "should return query with joins", %{
      with_assocs: permissions,
      actions_module: module
    } do
      assert {:ok, query} =
               EctoPermissions.construct_query(permissions, :delete, Resource, Resource, module)

      refute Enum.empty?(query.joins)
    end

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
      assert {:error, _q, condition_unconvertible: %{type: :function_2}} =
               EctoPermissions.construct_query(permissions, :delete, res, subject, module)

      assert {:error, _q, condition_unconvertible: _} =
               EctoPermissions.construct_query(permissions, :update, res, subject, module)

      assert {:error, _q, condition_unconvertible: %{type: :function_1}} =
               EctoPermissions.construct_query(permissions, :read, res, subject, module)

      assert {:error, _q, condition_unconvertible: %{type: :function_1}} =
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
