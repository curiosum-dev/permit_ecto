defmodule Permit.EctoFakeApp.Repo.Migrations.CreateItemTable do
  use Ecto.Migration

  def change do
    create table("item_metadata") do
      add :text, :string, default: ""
      add :item_id, references("items")

      timestamps()
    end

    create unique_index(:item_metadata, :item_id)
  end
end
