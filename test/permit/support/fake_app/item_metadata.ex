defmodule Permit.FakeApp.ItemMetadata do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset

  schema "item_metadata" do
    field(:text, :string)

    belongs_to(:item, Permit.FakeApp.Item, foreign_key: :item_id)

    timestamps()
  end

  @doc false
  def changeset(item, attrs) do
    item
    |> cast(attrs, [:item_id, :text])
  end
end
