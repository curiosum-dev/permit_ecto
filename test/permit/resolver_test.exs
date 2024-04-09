defmodule Permit.Ecto.ResolverTest do
  use Permit.RepoCase

  alias Permit.FakeApp.{Item, Repo, User}

  defmacro permissions_module(do: block) do
    inferred_modname =
      with {test_name_atom, _} <- __CALLER__.function do
        test_name_atom |> Atom.to_string() |> Macro.camelize() |> String.to_atom()
      end

    quote do
      {_, m, _, _} =
        defmodule unquote(inferred_modname) do
          use Permit.Ecto.Permissions,
            actions_module: Permit.FakeApp.PhoenixActions

          unquote(block)
        end

      m
    end
  end

  def authorization_module(permmodname) do
    [{authmodname, _}] =
      Code.compile_quoted(
        quote do
          modname = :"#{unquote(permmodname)}Authorization"

          defmodule modname do
            use Permit.Ecto,
              permissions_module: unquote(permmodname),
              repo: Permit.FakeApp.Repo
          end
        end
      )

    authmodname
  end

  setup do
    %{users: users, items: items} = Repo.seed_data!()

    {:ok, %{users: users, items: items}}
  end

  describe "authorize_and_preload_all!/5" do
    test "should return one record based on association" do
      authorization_module =
        permissions_module do
          def can(%{id: 1} = _user) do
            permit()
            |> read(Item, user: [id: 4, permission_level: 4], thread_name: "test")
            |> read(Item, item_metadata: [text: "Item 2"])
            |> read(Item, reviews: [accepted: true])
          end

          def can(_user), do: permit()
        end
        |> authorization_module()

      assert {:authorized, [%Item{id: 1}, %Item{id: 2}, %Item{id: 4}]} =
               Permit.Ecto.Resolver.authorize_and_preload_all!(
                 %User{id: 1},
                 authorization_module,
                 Item,
                 :index,
                 %{}
               )

      assert :unauthorized =
               Permit.Ecto.Resolver.authorize_and_preload_all!(
                 %User{id: 2},
                 authorization_module,
                 Item,
                 :index,
                 %{}
               )
    end

    test "retrieves all records if a restricted :all permission is overridden by a general :read permission" do
      authorization_module =
        permissions_module do
          def can(user) do
            permit()
            |> all(Item, owner_id: user.id)
            |> read(Item)
          end
        end
        |> authorization_module()

      assert {:authorized, [%Item{id: 1}, %Item{id: 2}, %Item{id: 3}, %Item{id: 4}]} =
               Permit.Ecto.Resolver.authorize_and_preload_all!(
                 %User{id: 1},
                 authorization_module,
                 Item,
                 :index,
                 %{}
               )
    end

    test "retrieves only limited records if a restricted :all permission is present" do
      authorization_module =
        permissions_module do
          def can(user) do
            permit()
            |> all(Item, owner_id: user.id)
          end
        end
        |> authorization_module()

      assert {:authorized, [%Item{id: 1}]} =
               Permit.Ecto.Resolver.authorize_and_preload_all!(
                 %User{id: 1},
                 authorization_module,
                 Item,
                 :index,
                 %{}
               )
    end

    test "returns :unauthorized for empty set of permissions" do
      authorization_module =
        permissions_module do
          def can(_user), do: permit()
        end
        |> authorization_module()

      assert :unauthorized =
               Permit.Ecto.Resolver.authorize_and_preload_all!(
                 %User{id: 1},
                 authorization_module,
                 Item,
                 :index,
                 %{}
               )
    end

    test "returns empty list when action is permitted but no records match" do
      authorization_module =
        permissions_module do
          def can(_user), do: permit() |> all(Item, owner_id: -1)
        end
        |> authorization_module()

      assert {:authorized, []} =
               Permit.Ecto.Resolver.authorize_and_preload_all!(
                 %User{id: 1},
                 authorization_module,
                 Item,
                 :index,
                 %{}
               )
    end

    test "returns records when some permissions match, other don't" do
      authorization_module =
        permissions_module do
          def can(user), do: permit() |> all(Item, owner_id: -1) |> all(Item, owner_id: user.id)
        end
        |> authorization_module()

      assert {:authorized, [%Item{owner_id: 1}]} =
               Permit.Ecto.Resolver.authorize_and_preload_all!(
                 %User{id: 1},
                 authorization_module,
                 Item,
                 :index,
                 %{}
               )
    end
  end
end
