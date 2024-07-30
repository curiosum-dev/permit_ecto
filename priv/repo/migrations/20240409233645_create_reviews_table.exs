defmodule Permit.EctoFakeApp.Repo.Migrations.CreateReviewsTable do
  use Ecto.Migration

  def change do
    create table("reviews") do
      add :accepted, :boolean, default: false
      add :item_id, references("items"), null: false
      add :user_id, references("users"), null: false

      timestamps()
    end

    create unique_index(:reviews, [:item_id, :user_id])
  end
end
