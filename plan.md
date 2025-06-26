# RepRivals - Bold & Energetic Workout Notebook Plan

## Completed
- [x] Generate Phoenix LiveView project "rep_rivals" with SQLite
- [x] Start server and create detailed plan
- [x] Replace home page with bold fitness-themed static mockup
- [x] Set up user authentication with mix phx.gen.auth
- [x] Create Workout schema and migration with required fields:
  - id, user_id, name (defaults to YYYYMMDD), description, metric, timestamps
- [x] Seed database with sample workouts (Helen, Jackie, Filthy Fifty, Wittman)
- [x] Build WorkoutNotebookLive (main screen) with:
  - "Create New Workout" button at top
  - Scrollable workout list with name + description preview
  - Sorting controls (alphabetical, date created, date modified)
  - Real-time updates via PubSub
- [ ] Build CreateWorkoutLive with:
  - Name input (defaults to YYYYMMDD format)
  - Description textarea (required)
  - METRIC dropdown ("For Time", "For Reps", "Weight")
  - "Add Workout to Library" button (conditional enabling)
- [ ] Build ViewEditWorkoutLive with:
  - Editable name and description fields
  - METRIC dropdown pre-selected
  - Save Changes button (conditional enabling)
  - Delete Workout button with confirmation modal
  - Display created/modified dates
- [x] Update router with authenticated routes (remove placeholder home route)
- [x] Style layouts for bold - [ ] Style layouts for bold & energetic fitness theme: energetic fitness theme:
  - Mobile-first responsive design
  - Bold colors, energetic typography
  - Clean spacing and intuitive tap targets
- [ ] Implement confirmation modal for workout deletion
- [ ] Add sorting functionality (alphabetical, date created, date modified)
- [ ] Test complete user flow (auth → notebook → create → edit → delete)
- [ ] Final verification and polish

## Design Theme: Bold & Energetic Fitness Brand
- High-contrast colors, bold typography
- Mobile-first with large tap targets
- Clean, motivating interface
- Fitness brand vibes throughout
