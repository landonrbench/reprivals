defmodule RepRivalsWeb.HomeLive do
  use RepRivalsWeb, :live_view

  alias RepRivals.Library
  alias RepRivals.Accounts

  @impl true
  def mount(_params, _session, socket) do
    user_id = socket.assigns.current_scope.user.id

    # Get workout stats
    workouts = Library.list_workouts_for_user(user_id)
    total_workouts = length(workouts)

    # Get week stats
    {week_start, _week_end} = get_current_week()

    workouts_this_week =
      Enum.count(workouts, fn workout ->
        NaiveDateTime.compare(workout.inserted_at, week_start) in [:gt, :eq]
      end)

    # Get unviewed challenge count for notification badge
    unviewed_challenges = Library.get_unviewed_challenge_count(user_id)

    socket =
      socket
      |> assign(:total_workouts, total_workouts)
      |> assign(:workouts_this_week, workouts_this_week)
      |> assign(:recent_workouts, Enum.take(workouts, 5))
      |> assign(:unviewed_challenges, unviewed_challenges)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="min-h-screen bg-gray-900 text-white">
        <!-- Header -->
        <div class="px-4 py-6">
          <div class="flex items-center justify-between">
            <div>
              <h1 class="text-2xl font-bold text-white">
                Welcome back, {String.upcase(@current_scope.user.email |> String.split("@") |> hd())}
              </h1>
              <p class="text-gray-400 text-sm mt-1">Ready to crush your next workout?</p>
            </div>
            <div class="w-10 h-10 bg-orange-500 rounded-full flex items-center justify-center">
              <span class="text-white font-bold text-lg">
                {String.upcase(@current_scope.user.email |> String.at(0))}
              </span>
            </div>
          </div>
        </div>
        
    <!-- Stats Cards -->
        <div class="px-4 pb-6">
          <div class="grid grid-cols-2 gap-4">
            <div class="bg-gray-800 rounded-lg p-4 border border-gray-700">
              <div class="text-2xl font-bold text-orange-500">{@total_workouts}</div>
              <div class="text-gray-400 text-sm">Total Workouts</div>
            </div>
            <div class="bg-gray-800 rounded-lg p-4 border border-gray-700">
              <div class="text-2xl font-bold text-green-500">{@workouts_this_week}</div>
              <div class="text-gray-400 text-sm">This Week</div>
            </div>
          </div>
        </div>
        
    <!-- Recent Workouts -->
        <div class="px-4 pb-20">
          <h2 class="text-lg font-semibold text-white mb-4">Recent Workouts</h2>
          <div class="space-y-3">
            <%= for workout <- @recent_workouts do %>
              <.link navigate={~p"/workouts/#{workout.id}"} class="block">
                <div class="bg-gray-800 border border-gray-700 rounded-lg p-4 hover:bg-gray-750 transition-colors">
                  <div class="flex items-center justify-between">
                    <div>
                      <h3 class="font-medium text-white">{workout.name}</h3>
                      <p class="text-gray-400 text-sm mt-1">
                        {get_workout_summary(workout)}
                      </p>
                    </div>
                    <div class="text-gray-500">
                      <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path
                          stroke-linecap="round"
                          stroke-linejoin="round"
                          stroke-width="2"
                          d="M9 5l7 7-7 7"
                        />
                      </svg>
                    </div>
                  </div>
                </div>
              </.link>
            <% end %>

            <%= if @recent_workouts == [] do %>
              <div class="text-center py-8">
                <div class="text-gray-500 mb-4">
                  <svg class="w-12 h-12 mx-auto" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10"
                    />
                  </svg>
                </div>
                <p class="text-gray-400">No workouts yet</p>
                <.link
                  navigate={~p"/notebook"}
                  class="text-orange-500 hover:text-orange-400 text-sm mt-2 inline-block"
                >
                  Create your first workout
                </.link>
              </div>
            <% end %>
          </div>
        </div>
        
    <!-- Bottom Navigation -->
        <div class="fixed bottom-0 left-0 right-0 bg-gray-800 border-t border-gray-700">
          <div class="flex items-center justify-around py-2">
            <.link
              navigate={~p"/notebook"}
              class="flex flex-col items-center py-2 px-4 text-gray-400 hover:text-orange-500 transition-colors"
            >
              <svg class="w-6 h-6 mb-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.746 0 3.332.477 4.5 1.253v13C19.832 18.477 18.246 18 16.5 18c-1.746 0-3.332.477-4.5 1.253"
                />
              </svg>
              <span class="text-xs">Notebook</span>
            </.link>

            <.link navigate={~p"/"} class="flex flex-col items-center py-2 px-4 text-orange-500">
              <svg class="w-6 h-6 mb-1" fill="currentColor" viewBox="0 0 24 24">
                <path d="M10 20v-6h4v6h5v-8h3L12 3 2 12h3v8z" />
              </svg>
              <span class="text-xs">Home</span>
            </.link>

            <.link
              navigate={~p"/challenges"}
              class="flex flex-col items-center py-2 px-4 text-gray-400 hover:text-orange-500 transition-colors relative"
            >
              <svg class="w-6 h-6 mb-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M9 12l2 2 4-4M7.835 4.697a3.42 3.42 0 001.946-.806 3.42 3.42 0 014.438 0 3.42 3.42 0 001.946.806 3.42 3.42 0 013.138 3.138 3.42 3.42 0 00.806 1.946 3.42 3.42 0 010 4.438 3.42 3.42 0 00-.806 1.946 3.42 3.42 0 01-3.138 3.138 3.42 3.42 0 00-1.946.806 3.42 3.42 0 01-4.438 0 3.42 3.42 0 00-1.946-.806 3.42 3.42 0 01-3.138-3.138 3.42 3.42 0 00-.806-1.946 3.42 3.42 0 010-4.438 3.42 3.42 0 00.806-1.946 3.42 3.42 0 013.138-3.138z"
                />
              </svg>
              <%= if @unviewed_challenges > 0 do %>
                <span class="absolute -top-1 -right-1 bg-red-500 text-white text-xs rounded-full h-5 w-5 flex items-center justify-center">
                  {@unviewed_challenges}
                </span>
              <% end %>
              <span class="text-xs">Challenges</span>
            </.link>

            <.link
              navigate={~p"/friends"}
              class="flex flex-col items-center py-2 px-4 text-gray-400 hover:text-orange-500 transition-colors"
            >
              <svg class="w-6 h-6 mb-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197m13.5-9a2.5 2.5 0 11-5 0 2.5 2.5 0 015 0z"
                />
              </svg>
              <span class="text-xs">Friends</span>
            </.link>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  defp get_workout_summary(workout) do
    case workout.primary_metric do
      "time" -> "For Time"
      "reps" -> "For Reps"
      "weight" -> "For Load"
      "distance" -> "For Distance"
      _ -> "Workout"
    end
  end

  defp get_current_week do
    now = NaiveDateTime.utc_now()
    days_since_monday = NaiveDateTime.day_of_week(now) - 1
    week_start = NaiveDateTime.add(now, -days_since_monday * 24 * 60 * 60, :second)
    week_end = NaiveDateTime.add(week_start, 6 * 24 * 60 * 60, :second)
    {week_start, week_end}
  end
end
