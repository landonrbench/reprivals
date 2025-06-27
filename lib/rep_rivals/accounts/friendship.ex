defmodule RepRivals.Accounts.Friendship do
  use Ecto.Schema
  import Ecto.Changeset

  alias RepRivals.Accounts.User

  schema "friendships" do
    field :status, :string, default: "pending"

    belongs_to :user, User
    belongs_to :friend, User

    timestamps()
  end

  @doc false
  def changeset(friendship, attrs) do
    friendship
    |> cast(attrs, [:user_id, :friend_id, :status])
    |> validate_required([:user_id, :friend_id, :status])
    |> validate_inclusion(:status, ["pending", "accepted", "blocked"])
    |> validate_different_users()
    |> unique_constraint([:user_id, :friend_id])
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:friend_id)
  end

  defp validate_different_users(changeset) do
    user_id = get_field(changeset, :user_id)
    friend_id = get_field(changeset, :friend_id)

    if user_id && friend_id && user_id == friend_id do
      add_error(changeset, :friend_id, "cannot add yourself as a friend")
    else
      changeset
    end
  end

  @doc """
  Returns true if the friendship represents an accepted friendship.
  """
  def accepted?(%__MODULE__{status: "accepted"}), do: true
  def accepted?(_), do: false

  @doc """
  Returns true if the friendship is still pending.
  """
  def pending?(%__MODULE__{status: "pending"}), do: true
  def pending?(_), do: false
end
