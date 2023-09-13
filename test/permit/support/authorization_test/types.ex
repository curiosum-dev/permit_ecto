defmodule Permit.AuthorizationTest.Types do
  defmodule TestUser do
    @moduledoc false

    defstruct [:id, :role, :overseer_id, :some_string]

    defimpl Permit.SubjectMapping, for: Permit.AuthorizationTest.Types.TestUser do
      def subjects(user), do: [user.role]
    end
  end

  defmodule TestUserAsRole do
    @moduledoc false

    defstruct [:id, :role, :overseer_id]

    defimpl Permit.SubjectMapping, for: Permit.AuthorizationTest.Types.TestUserAsRole do
      def subjects(user), do: [user]
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
