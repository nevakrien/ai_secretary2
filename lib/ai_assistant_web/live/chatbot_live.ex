defmodule AiAssistantWeb.ChatbotLive do
  use Phoenix.LiveView#, container: {:div, [class: "fixed left-0 bottom-0 mr-4"]}

  alias Phoenix.LiveView.JS

  alias AiAssistant.Chatbot
  alias AiAssistant.Chatbot.Message

  @impl true
  def mount(_params, session, socket) do

    user_id = session["current_user_id"]

    conversation =Chatbot.get_conversation(user_id)
    previous_messages = Chatbot.list_messages_for_conversations(conversation.id)
    {
      :ok,
      socket
      |> assign(:conversation, conversation)
      |> assign(:message, %Message{})
      |> assign(:messages, previous_messages)

      |> assign(:loading, false)
      |> assign(:call_ref, nil) 
    }
  end

  @impl true
  def handle_info({AiAssistantWeb.ChatbotLive.FormComponent, {:saved, message}}, socket) do
    messages = [message|socket.assigns.messages]

    task=Task.async(fn ->
      Chatbot.generate_response(socket.assigns.conversation, messages)
    end)

    {
      :noreply,
      socket
      |> assign(:message, %Message{})
      |> assign(:messages, messages)
      |> assign(:loading, true)
      |> assign(:call_ref, task.ref) 
    }
  end

  def handle_info({ref, result}, socket) when is_reference(ref) and ref == socket.assigns.call_ref do
    Process.demonitor(ref, [:flush])

    messages =
      case result do
        {:ok, message} -> [message|socket.assigns.messages]
        _ -> socket.assigns.messages
      end

    {
      :noreply,
      socket
      |> assign(:messages, messages)
      |> assign(:loading, false)
      |> assign(:call_ref, nil) 
    }
  end

  # If the task fails...
  def handle_info({:DOWN, ref, _, _, _}, socket) when is_reference(ref) and ref == socket.assigns.call_ref do
    {
      :noreply,
      socket
      |> assign(:loading, false)
      |> assign(:call_ref, nil) 
    }
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex flex-col flex-grow w-full max-w-xl bg-white shadow-xl rounded-t-lg overflow-hidden">
      <div class="flex flex-col flex-grow p-4 overflow-auto max-h-[--chat-max-height]">
        
        <%= for message <- Enum.reverse(@messages) do %>
          <div id={"message-#{message.id}"} phx-mounted={JS.dispatch("scrollIntoView", to: "#message-#{message.id}")}>
            <div :if={message.role == "user"} class="flex w-full mt-2 space-x-3 max-w-xs ml-auto justify-end">
              <div>
                <div class="bg-blue-600 text-white p-3 rounded-l-lg rounded-br-lg">
                  <p class="text-sm whitespace-pre-line"><%= message.content %></p>
                </div>
                <span class="text-xs text-gray-500 leading-none">Now</span>
              </div>
              <img class="flex-shrink-0 h-10 w-10 rounded-full bg-gray-300" src="https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQuMDxyday8jmFWbCfVnAIZAMsAXNSUA_T_fEPgJuDXJg&s" alt="">
            </div>

            <div :if={message.role == "assistant"} class="flex w-full mt-2 space-x-3 max-w-xs">
              <img class="flex-shrink-0 h-10 w-10 rounded-full bg-gray-300" src="https://images.unsplash.com/photo-1589254065878-42c9da997008?ixlib=rb-1.2.1&amp;ixid=eyJhcHBfaWQiOjEyMDd9&amp;auto=format&amp;fit=facearea&amp;facepad=2&amp;w=256&amp;h=256&amp;q=80" alt="">
              <div>
                <div class="bg-gray-300 p-3 rounded-r-lg rounded-bl-lg">
                  <p class="text-sm whitespace-pre-line"><%= message.content %></p>
                </div>
                <span class="text-xs text-gray-500 leading-none">Now</span>
              </div>
            </div>
          </div>
        <% end %>
      </div>

      <div class="bg-gray-300 p-4">
        <.live_component
          module={AiAssistantWeb.ChatbotLive.FormComponent}
          id="new-message"
          conversation={@conversation}
          message={@message}
          loading={@loading}
        />
      </div>
    </div>
    """
  end
end