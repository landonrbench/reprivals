defmodule RepRivals.Library.Challenge do
  use Ecto.Schema
  import Ecto.Changeset

  alias RepRivals.Accounts.User
  alias RepRivals.Library.Workout
  alias RepRivals.Library.ChallengeParticipant

  schema "challenges" do
    field :name, :string
    field :description, :string
    field :status, :string, default: "active"
    field :expires_at, :naive_datetime

    belongs_to :creator, User
    belongs_to :workout, Workout
    has_many :participants, ChallengeParticipant

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(challenge, attrs) do
    challenge
    |> cast(attrs, [:name, :description, :status, :expires_at, :creator_id, :workout_id])
    |> validate_required([:name, :creator_id, :workout_id])
    |> validate_inclusion(:status, ["active", "completed", "expired"])
    |> foreign_key_constraint(:creator_id)
    |> foreign_key_constraint(:workout_id)
  end

  def create_changeset(attrs) do
    %__MODULE__{}
    |> changeset(attrs)
  end

  def status_options do
    [
      {"Active", "active"},
      {"Completed", "completed"},
      {"Expired", "expired"}
    ]
  end

  def active?(challenge) do
    challenge.status == "active"
  end

  def expired?(challenge) do
    challenge.status == "expired" or
      (challenge.expires_at &&
         NaiveDateTime.compare(challenge.expires_at, NaiveDateTime.utc_now()) == :lt)
  end
end
