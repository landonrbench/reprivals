defmodule RepRivals.LibraryFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `RepRivals.Library` context.
  """

  alias RepRivals.Library

  @doc """
  Generate a workout.
  """
  def workout_fixture(attrs \\ %{}) do
    {:ok, workout} =
      attrs
      |> Enum.into(%{
        name: "Test Workout",
        description: "A test workout description",
        metric: "time",
        user_id: 1
      })
      |> Library.create_workout()

    workout
  end

  @doc """
  Generate a challenge.
  """
  def challenge_fixture(attrs \\ %{}) do
    {:ok, challenge} =
      attrs
      |> Enum.into(%{
        name: "Test Challenge",
        description: "A test challenge description",
        status: "active",
        creator_id: 1,
        workout_id: 1,
        expires_at: DateTime.add(DateTime.utc_now(), 7, :day)
      })
      |> Library.create_challenge()

    challenge
  end

  @doc """
  Generate a challenge participant.
  """
  def challenge_participant_fixture(attrs \\ %{}) do
    {:ok, participant} =
      attrs
      |> Enum.into(%{
        challenge_id: 1,
        user_id: 1,
        status: "invited"
      })
      |> Library.create_challenge_participant()

    participant
  end

  @doc """
  Generate a friendship.
  """
  def friendship_fixture(attrs \\ %{}) do
    {:ok, friendship} =
      attrs
      |> Enum.into(%{
        user_id: 1,
        friend_id: 2,
        status: "accepted"
      })
      |> Library.create_friendship()

    friendship
  end

  @doc """
  Generate multiple challenge participants for a challenge.
  """
  def challenge_participants_fixture(challenge_id, user_ids) do
    {:ok, participants} = Library.create_challenge_participants(challenge_id, user_ids)
    participants
  end
end
