defmodule Permit.AuthorizationTest.Types do
  # TODO: These should be Ecto schemas?
  defmodule TestUser do
    @moduledoc false

    defstruct [:id, :role, :overseer_id, :some_string]

    defimpl Permit.HasRoles, for: Permit.AuthorizationTest.Types.TestUser do
      def roles(user), do: [user.role]
    end
  end

  defmodule TestUserAsRole do
    @moduledoc false

    defstruct [:id, :role, :overseer_id]

    defimpl Permit.HasRoles, for: Permit.AuthorizationTest.Types.TestUserAsRole do
      def roles(user), do: [user]
    end
  end

  defmodule TestObject do
    @moduledoc false
    use Ecto.Schema

    schema "test_objects" do
      field(:name, :string)
      field(:owner_id, :integer)
      field(:manager_id, :integer, default: 0)
      field(:field_1, :integer)
      field(:field_2, :integer)
    end
  end
end
