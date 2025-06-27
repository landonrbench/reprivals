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

