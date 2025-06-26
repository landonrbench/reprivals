defmodule RepRivalsWeb.PageController do
  use RepRivalsWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
