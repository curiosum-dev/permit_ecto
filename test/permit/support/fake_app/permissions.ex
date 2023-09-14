defmodule Permit.FakeApp.Permissions do
  @moduledoc false
  use Permit.Ecto.Permissions, actions_module: Permit.FakeApp.PhoenixActions

  alias Permit.FakeApp.Item
  alias Permit.FakeApp.User

  def can(:admin = _role) do
    permit()
    |> all(Item)
  end

  def can(:owner = _role) do
    permit()
    |> all(Item, fn user, item -> item.owner_id == user.id end)
  end

  def can(:inspector = _role) do
    permit()
    |> read(Item)
  end

  def can(%{role: :moderator, level: 1} = _role) do
    permit()
    |> all(Item, permission_level: {:<=, 1})
  end

  def can(%{role: :moderator, level: 2} = _role) do
    permit()
    |> all(Item, permission_level: {{:not, :>}, 2})
  end

  def can(%{role: :thread_moderator, thread_name: thread} = _role) do
    permit()
    |> all(Item, permission_level: {:<=, 3}, thread_name: {:ilike, thread})
  end

  def can(%User{id: id} = _role) do
    permit()
    |> all(Item, owner_id: id)
  end

  def can(_role), do: permit()
end
