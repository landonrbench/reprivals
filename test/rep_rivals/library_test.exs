defmodule RepRivals.LibraryTest do
  use RepRivals.DataCase

  alias RepRivals.Library
  alias RepRivals.Library.{Challenge, ChallengeParticipant}

  describe "create_group_challenge/2" do
    test "creates challenge with creator as accepted participant and others as invited" do
      # Create test users
      creator = RepRivals.AccountsFixtures.user_fixture()
      friend1 = RepRivals.AccountsFixtures.user_fixture()
      friend2 = RepRivals.AccountsFixtures.user_fixture()

      # Create a workout
      workout_attrs = %{
        name: "Test Workout",
        description: "A test workout",
        metric: "For Time",
        user_id: creator.id
      }

      {:ok, workout} = Library.create_workout(workout_attrs)

      # Create group challenge
      challenge_attrs = %{
        name: "Morning WOD",
        description: "Let's crush this together!",
        workout_id: workout.id,
        creator_id: creator.id
      }

      participant_ids = [friend1.id, friend2.id]

      {:ok, {challenge, participants}} = Library.create_group_challenge(challenge_attrs, participant_ids)

      # Verify challenge was created
      assert %Challenge{} = challenge
      assert challenge.name == "Morning WOD"
      assert challenge.creator_id == creator.id

      # Get all participants
      participants = Library.list_challenge_participants(challenge.id)
      assert length(participants) == 3

      # Verify creator has "accepted" status
      creator_participant = Enum.find(participants, &(&1.user_id == creator.id))
      assert creator_participant.status == "accepted"

      # Verify friends have "invited" status
      friend_participants = Enum.filter(participants, &(&1.user_id != creator.id))
      assert length(friend_participants) == 2
      assert Enum.all?(friend_participants, &(&1.status == "invited"))
    end
  end
end
