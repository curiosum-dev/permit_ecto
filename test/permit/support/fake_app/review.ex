defmodule Permit.FakeApp.Review do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset

  schema "reviews" do
    field(:accepted, :boolean)

    belongs_to(:item, Permit.FakeApp.Item, foreign_key: :item_id)
    belongs_to(:user, Permit.FakeApp.User, foreign_key: :user_id)

    timestamps()
  end

  @doc false
  def changeset(item, attrs) do
    item
    |> cast(attrs, [:accepted, :item_id, :user_id])
  end
end
