defmodule AiAssistantWeb.PageController do
  use AiAssistantWeb, :controller
  #alias AiAssistantWeb.Router.Helpers, as: Routes

  def home(conn, _params) do
    render(conn, :home)#, layout: false
  end

  def taskboard(conn, _params) do
    render(conn, :taskboard)#, layout: false
  end
end
