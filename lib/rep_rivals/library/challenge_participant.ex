defmodule RepRivals.Library.ChallengeParticipant do
  use Ecto.Schema
  import Ecto.Changeset

  alias RepRivals.Accounts.User
  alias RepRivals.Library.Challenge

  schema "challenge_participants" do
    field :status, :string, default: "invited"
    field :result_value, :decimal
    field :result_unit, :string
    field :result_notes, :string
    field :completed_at, :naive_datetime
    field :viewed_at, :naive_datetime

    belongs_to :challenge, Challenge
    belongs_to :user, User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(participant, attrs) do
    participant
    |> cast(attrs, [
      :status,
      :result_value,
      :result_unit,
      :result_notes,
      :completed_at,
      :viewed_at,
      :challenge_id,
      :user_id
    ])
    |> validate_required([:challenge_id, :user_id])
    |> validate_inclusion(:status, ["invited", "accepted", "declined", "completed"])
    |> foreign_key_constraint(:challenge_id)
    |> foreign_key_constraint(:user_id)
    |> unique_constraint([:challenge_id, :user_id])
  end

  def create_changeset(attrs) do
    %__MODULE__{}
    |> changeset(attrs)
  end

  def status_options do
    [
      {"Invited", "invited"},
      {"Accepted", "accepted"},
      {"Declined", "declined"},
      {"Completed", "completed"}
    ]
  end

  def completed?(participant) do
    participant.status == "completed"
  end

  def pending?(participant) do
    participant.status == "invited"
  end

  def accepted?(participant) do
    participant.status in ["accepted", "completed"]
  end
end
