defmodule RepRivalsWeb.ChallengesLiveInvitationTest do
  use RepRivalsWeb.ConnCase, async: true
  import Phoenix.LiveViewTest
  import RepRivals.AccountsFixtures
  import RepRivals.LibraryFixtures

  alias RepRivals.{Library, Repo}

  describe "Challenge Invitation and Acceptance" do
    setup do
      # Create test users
      creator = user_fixture(%{email: "creator@example.com"})
      invitee = user_fixture(%{email: "invitee@example.com"})

      # Create a workout for the challenge
      workout =
        workout_fixture(%{
          name: "Test Workout",
          description: "5 rounds for time",
          metric: "For Time",
          user_id: creator.id
        })

      # Create a challenge
      {:ok, challenge} =
        Library.create_challenge(%{
          name: "Test Challenge",
          description: "A test challenge",
          status: "active",
          creator_id: creator.id,
          workout_id: workout.id,
          expires_at: DateTime.add(DateTime.utc_now(), 7, :day)
        })

      # Create challenge participants (creator and invitee)
      {:ok, _creator_participant} =
        Library.create_challenge_participants(challenge.id, [creator.id])

      {:ok, invitee_participant} =
        Library.create_challenge_participants(challenge.id, [invitee.id])

      %{
        creator: creator,
        invitee: invitee,
        challenge: challenge,
        workout: workout,
        invitee_participant: List.first(invitee_participant)
      }
    end

    test "invitee can view challenge invitation in invites tab", %{
      conn: conn,
      invitee: invitee,
      challenge: challenge,
      workout: workout
    } do
      # Log in as the invitee
      conn = log_in_user(conn, invitee)

      # Visit the challenges page
      {:ok, view, html} = live(conn, ~p"/challenges")

      # Verify the page loads with the invitee logged in
      assert html =~ invitee.email
      assert html =~ "Challenges"

      # Initially on "My Challenges" tab - should show no challenges created
      assert html =~ "No challenges created yet"

      # Click the "Invites" tab
      html = view |> element("button[phx-value-tab='invites']") |> render_click()

      # Verify the challenge invitation is displayed
      assert html =~ challenge.name
      assert html =~ workout.name
      assert html =~ "🟡 Invited"
      assert html =~ "Accept Challenge"
    end

    test "invitee can accept challenge invitation", %{
      conn: conn,
      invitee: invitee,
      invitee_participant: participant
    } do
      # Verify initial participant status
      assert participant.status == "invited"

      # Log in as the invitee
      conn = log_in_user(conn, invitee)

      # Visit the challenges page
      {:ok, view, _html} = live(conn, ~p"/challenges")

      # Switch to invites tab
      view |> element("button[phx-value-tab='invites']") |> render_click()

      # Accept the challenge
      html =
        view
        |> element(
          "button[phx-click='accept_challenge'][phx-value-participant_id='#{participant.id}']"
        )
        |> render_click()

      # Verify the UI shows accepted status
      assert html =~ "🟡 Accepted"
      refute html =~ "Accept Challenge"

      # Verify the database was updated
      updated_participant = Repo.get(Library.ChallengeParticipant, participant.id)
      assert updated_participant.status == "accepted"
    end

    test "accepted participant can see completion interface", %{
      conn: conn,
      invitee: invitee,
      invitee_participant: participant
    } do
      # First accept the challenge
      {:ok, accepted_participant} =
        Library.update_challenge_participant(participant, %{status: "accepted"})

      # Log in as the invitee
      conn = log_in_user(conn, invitee)

      # Visit the challenges page
      {:ok, view, _html} = live(conn, ~p"/challenges")

      # Switch to invites tab
      html = view |> element("button[phx-value-tab='invites']") |> render_click()

      # Verify accepted status and completion interface
      assert html =~ "🟡 Accepted"
      assert html =~ "Complete Challenge"

      # Click complete challenge button to show completion form
      html =
        view
        |> element(
          "button[phx-click='show_complete_form'][phx-value-participant_id='#{accepted_participant.id}']"
        )
        |> render_click()

      # Verify completion form is displayed
      assert html =~ "Complete Challenge"
      assert html =~ "Result"
      assert html =~ "Notes"
      assert html =~ "Submit Result"
    end

    test "participant can complete challenge with results", %{
      conn: conn,
      invitee: invitee,
      invitee_participant: participant
    } do
      # Accept the challenge first
      {:ok, accepted_participant} =
        Library.update_challenge_participant(participant, %{status: "accepted"})

      # Log in as the invitee
      conn = log_in_user(conn, invitee)

      # Visit the challenges page
      {:ok, view, _html} = live(conn, ~p"/challenges")

      # Switch to invites tab and show completion form
      view |> element("button[phx-value-tab='invites']") |> render_click()

      view
      |> element(
        "button[phx-click='show_complete_form'][phx-value-participant_id='#{accepted_participant.id}']"
      )
      |> render_click()

      # Submit completion form
      html =
        view
        |> form("#complete-form-#{accepted_participant.id}", %{
          "result_value" => "12.50",
          "result_unit" => "minutes",
          "result_notes" => "Great workout!"
        })
        |> render_submit()

      # Verify completion success message and UI update
      assert html =~ "Challenge completed successfully!"
      assert html =~ "✅ Completed"
      assert html =~ "12.50 minutes"

      # Verify database was updated with completion
      completed_participant = Repo.get(Library.ChallengeParticipant, accepted_participant.id)
      assert completed_participant.status == "completed"
      assert Decimal.equal?(completed_participant.result_value, Decimal.new("12.50"))
      assert completed_participant.result_unit == "minutes"
      assert completed_participant.result_notes == "Great workout!"
      assert completed_participant.completed_at != nil
    end

    test "multiple participants create proper leaderboard", %{
      conn: conn,
      creator: creator,
      invitee: invitee,
      challenge: challenge
    } do
      # Get participants and complete the challenge for both
      creator_participant =
        Repo.get_by(Library.ChallengeParticipant, challenge_id: challenge.id, user_id: creator.id)

      invitee_participant =
        Repo.get_by(Library.ChallengeParticipant, challenge_id: challenge.id, user_id: invitee.id)

      # Creator completes with faster time
      {:ok, _} =
        Library.update_challenge_participant(creator_participant, %{
          status: "completed",
          result_value: Decimal.new("10.25"),
          result_unit: "minutes",
          result_notes: "Fast finish!",
          completed_at: DateTime.utc_now()
        })

      # Invitee completes with slower time
      {:ok, _} =
        Library.update_challenge_participant(invitee_participant, %{
          status: "completed",
          result_value: Decimal.new("12.75"),
          result_unit: "minutes",
          result_notes: "Good effort!",
          completed_at: DateTime.utc_now()
        })

      # Log in as invitee to view leaderboard
      conn = log_in_user(conn, invitee)
      {:ok, view, _html} = live(conn, ~p"/challenges")

      # Switch to invites tab to see completed challenge
      html = view |> element("button[phx-value-tab='invites']") |> render_click()

      # Verify leaderboard shows both participants with correct order and results
      assert html =~ "✅ Completed"
      # Creator's faster time
      assert html =~ "10.25 minutes"
      # Invitee's slower time
      assert html =~ "12.75 minutes"

      # Verify both participant emails are shown
      assert html =~ creator.email
      assert html =~ invitee.email
    end
  end
end
