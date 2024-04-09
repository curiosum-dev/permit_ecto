defmodule Permit.FakeApp.Item do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset

  schema "items" do
    field(:permission_level, :integer)
    field(:thread_name, :string)

    belongs_to(:user, Permit.FakeApp.User, foreign_key: :owner_id)

    has_one(:item_metadata, Permit.FakeApp.ItemMetadata)
    has_many(:reviews, Permit.FakeApp.Review)

    timestamps()
  end

  @doc false
  def changeset(item, attrs) do
    item
    |> cast(attrs, [:permission_level, :thread_name, :owner_id])
  end
end
