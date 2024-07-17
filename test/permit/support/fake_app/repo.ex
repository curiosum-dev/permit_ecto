defmodule Permit.FakeApp.Repo do
  use Ecto.Repo,
    otp_app: :permit_ecto,
    adapter: Ecto.Adapters.Postgres

  alias Permit.FakeApp.{User, Item, ItemMetadata, Repo, Review}

  def seed_data! do
    users = [
      %User{id: 1} |> Repo.insert!(),
      %User{id: 2} |> Repo.insert!(),
      %User{id: 3} |> Repo.insert!(),
      %User{id: 4, permission_level: 4} |> Repo.insert!()
    ]

    items = [
      %Item{id: 1, owner_id: 1, permission_level: 1} |> Repo.insert!(),
      %Item{id: 2, owner_id: 2, permission_level: 2, thread_name: "dmt"} |> Repo.insert!(),
      %Item{id: 3, owner_id: 3, permission_level: 3} |> Repo.insert!(),
      %Item{id: 4, owner_id: 4, thread_name: "test"} |> Repo.insert!()
    ]

    item_metadata = [
      %ItemMetadata{id: 1, item_id: 1, text: "Item 1"} |> Repo.insert(),
      %ItemMetadata{id: 2, item_id: 2, text: "Item 2"} |> Repo.insert(),
      %ItemMetadata{id: 3, item_id: 3, text: "Item 3"} |> Repo.insert()
    ]

    _reviews = [
      %Review{user_id: 1, item_id: 1, accepted: true} |> Repo.insert(),
      %Review{user_id: 2, item_id: 1, accepted: false} |> Repo.insert(),
      %Review{user_id: 3, item_id: 2, accepted: false} |> Repo.insert()
    ]

    %{users: users, items: items, item_metadata: item_metadata}
  end
end
