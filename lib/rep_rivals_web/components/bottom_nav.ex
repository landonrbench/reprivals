defmodule RepRivalsWeb.Components.BottomNav do
  use Phoenix.Component
  import RepRivalsWeb.CoreComponents

  attr :current_page, :string, default: ""
  attr :class, :string, default: ""

  def bottom_nav(assigns) do
    ~H"""
    <nav class={[
      "fixed bottom-0 left-0 right-0 bg-white border-t border-gray-200 z-50",
      "safe-area-pb",
      @class
    ]}>
      <div class="flex justify-around items-center py-2 px-4 max-w-md mx-auto">
        <!-- Dashboard -->
        <.nav_item href="/" icon="hero-home" label="Home" active={@current_page == "dashboard"} />
        
    <!-- Workouts -->
        <.nav_item
          href="/workouts"
          icon="hero-clipboard-document-list"
          label="Workouts"
          active={@current_page == "workouts"}
        />
        
    <!-- Leaderboard -->
        <.nav_item
          href="/leaderboard"
          icon="hero-trophy"
          label="Leaderboard"
          active={@current_page == "leaderboard"}
        />
        
    <!-- Friends -->
        <.nav_item
          href="/friends"
          icon="hero-users"
          label="Friends"
          active={@current_page == "friends"}
        />
      </div>
    </nav>
    """
  end

  attr :href, :string, required: true
  attr :icon, :string, required: true
  attr :label, :string, required: true
  attr :active, :boolean, default: false

  defp nav_item(assigns) do
    ~H"""
    <.link
      navigate={@href}
      class={[
        "flex flex-col items-center justify-center px-2 py-1 rounded-lg transition-colors",
        if(@active, do: "text-blue-600 bg-blue-50", else: "text-gray-600 hover:text-gray-900")
      ]}
    >
      <.icon
        name={@icon}
        class={[
          "w-6 h-6 mb-1",
          if(@active, do: "text-blue-600", else: "text-gray-600")
        ]}
      />
      <span class={[
        "text-xs font-medium",
        if(@active, do: "text-blue-600", else: "text-gray-600")
      ]}>
        {@label}
      </span>
    </.link>
    """
  end
end
