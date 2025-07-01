defmodule RepRivalsWeb.Components.BottomNavbar do
  use Phoenix.Component

  @doc """
  Renders the bottom navigation bar with consistent styling across all pages.

  ## Examples

      <.bottom_navbar current_page="home" />
      <.bottom_navbar current_page="notebook" />
      <.bottom_navbar current_page="friends" />
      <.bottom_navbar current_page="challenges" />
  """
  attr :current_page, :string, required: true

  def bottom_navbar(assigns) do
    ~H"""
    <!-- Bottom Navigation -->
    <div class="fixed bottom-0 left-0 right-0 bg-gray-800 border-t border-gray-700">
      <div class="flex justify-around py-3">
        <a
          href="/notebook"
          class={[
            "flex flex-col items-center transition-colors",
            if(@current_page == "notebook",
              do: "text-orange-500",
              else: "text-gray-400 hover:text-white"
            )
          ]}
        >
          <div class="text-xl mb-1">📝</div>
          <span class="text-xs font-semibold">Notebook</span>
        </a>
        <a
          href="/"
          class={[
            "flex flex-col items-center transition-colors",
            if(@current_page == "home", do: "text-orange-500", else: "text-gray-400 hover:text-white")
          ]}
        >
          <div class="text-xl mb-1">🏠</div>
          <span class="text-xs font-semibold">Home</span>
        </a>
        <a
          href="/challenges"
          class={[
            "flex flex-col items-center transition-colors",
            if(@current_page == "challenges",
              do: "text-orange-500",
              else: "text-gray-400 hover:text-white"
            )
          ]}
        >
          <div class="text-xl mb-1">🏆</div>
          <span class="text-xs font-semibold">Challenges</span>
        </a>
        <a
          href="/friends"
          class={[
            "flex flex-col items-center transition-colors",
            if(@current_page == "friends",
              do: "text-orange-500",
              else: "text-gray-400 hover:text-white"
            )
          ]}
        >
          <div class="text-xl mb-1">👥</div>
          <span class="text-xs font-semibold">Friends</span>
        </a>
      </div>
    </div>
    """
  end
end
