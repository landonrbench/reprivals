# RepRivals - Workout CRUD Features Plan

## Current Status
- [x] Base app with authentication working
- [x] WorkoutNotebookLive displaying existing workouts
- [x] Database seeded with demo user and sample workouts

## New Features to Build
- [x] Create New Workout LiveView (`/workouts/new`)
  - Form with name input (defaulted to current date YYYYMMDD)
  - Description textarea (required)
  - Metric dropdown (For Time, For Reps, Weight)
  - "Add Workout to Library" button (enabled when valid)
- [x] Edit Workout LiveView (`/workouts/:id/edit`)
  - Pre-populated form with existing workout data
  - Save Changes button
  - Delete Workout button with confirmation modal
  - Display created/modified timestamps
- [x] Update WorkoutNotebookLive
  - Add "Create New Workout" button navigation
  - Make workout items clickable to edit
- [x] Router Updates
  - Add new routes for create/edit workflows
- [x] Library Context Enhancements
  - Add `update_workout/2` and `delete_workout/1` functions
  - Add `get_workout!/1` for fetching single workout
- [x] Test the complete workflow

## New Workout Results Tracking Features
- [x] Database: `workout_results` table with user_id, workout_id, result_value, notes, logged_at
- [x] Schema: `WorkoutResult` with proper validations
- [x] Context: Added workout result CRUD functions to Library
- [x] LiveView: `WorkoutDetailLive` showing workout info, results history, and logging
- [x] Dynamic "Log New [Metric]" button based on workout metric type
- [x] Progress Chart: Canvas-based chart showing results over time
- [x] Results History: Chronological list with dates, results, and notes
- [x] Router: Updated workout clicks to go to detail page instead of edit

