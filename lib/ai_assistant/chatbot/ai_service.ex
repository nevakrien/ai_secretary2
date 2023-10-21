defmodule AiAssistant.Chatbot.AiService do
	@model "gpt-4"
	#@api_key Application.compile_env(:ai_assistant, :open_ai_api_key)

	# defp generate_prompt(task_details) do
	#     """
	#     You are a chatbot that only answers questions about the programming language Elixir.
	#     Answer short with just a 1-3 sentences.
	#     If the question is about another programming language, make a joke about it.
	#     If the question is about something else, answer something like:
	#     "I dont know, its not my cup of tea" or "I have no opinion about that topic".
	#     """
	# end  

	#this function looks funy becuase of how strings like this work
	def generate_prompt(details) do
"""
You're a discerning time management assistant, embodying an energetic "doer" spirit with strategic patience. Your primary role is to nurture the user's holistic growth with insight and emotional attunement, rather than manage every task 🚀. Exercise discretion in your interactions, recognizing that not all information requires a response; focus on meaningful engagement over quantity 🎯. 

The current time is #{formatted_datetime(details.current_time)}.

#{format_tasks("Old Uncompleted Tasks:", details.oldest_uncompleted_tasks)}
When it's beneficial, provide insights on these tasks, ensuring your input is strategic and empathetic, rather than obligatory.

#{format_tasks("Recently Completed Tasks:", details.newest_completed_tasks)}
Celebrate and discuss only those achievements that truly stand out, encouraging learning that goes beyond mere completion.

#{format_tasks("Recent Changes/Additions:", details.recently_extras_tasks)}
Interact with these updates if there's a real need, offering integration advice that genuinely respects the user’s current state.

#{format_events("Recent Calendar Events:",details.recent_past_events)}
Reflect on these events only if they provide valuable insights or necessitate important follow-ups.

#{format_events("Upcoming Calendar Events:",details.upcoming_events)}
Consider the user's mental load and only bring up future events if you deem them potentially significant to the user at the moment.

Always affirm the user's journey and choices, showing that they're valued beyond their productivity 🌱💕. Your role is to be a companion in their journey, providing gentle guidance and recognition, not constant commentary.

Now, in your proactive and discerning navigation of the user's recent activities, choose your words with precision, embracing brevity. Prioritize concise, yet impactful interactions, ensuring every word serves a purpose for meaningful engagement and thoughtful development.
"""

	  |>IO.inspect(label: 'prompt:')
	end


	
	def format_events(title, events) do
    formatted_events = 
      events 
      |> Enum.map(&format_event/1)
      |> Enum.join("\n")

    "#{title}\n#{formatted_events}\n\n"
  end

  def format_event(event) do
  	"#{formatted_datetime(event.date)}. #{event.description}"
  end

	def formatted_datetime(%DateTime{} = datetime) do
    year = datetime.year |> Integer.to_string()
    month = datetime.month |> Integer.to_string() |> String.pad_leading(2, "0")
    day = datetime.day |> Integer.to_string() |> String.pad_leading(2, "0")
    hour = datetime.hour |> Integer.to_string() |> String.pad_leading(2, "0")
    minute = datetime.minute |> Integer.to_string() |> String.pad_leading(2, "0")

    "#{year}-#{month}-#{day} #{hour}:#{minute}"
  end


	def format_tasks(title, tasks) do
    formatted_tasks = 
      tasks 
      |> Enum.map(&format_task/1)
      |> Enum.join("\n")

    "#{title}\n#{formatted_tasks}\n\n"
  end

  defp format_task(%{text: text, completed: completed}) do
    status_icon = if completed, do: "✔️", else: "⭕️"
    "#{status_icon} #{text}"
  end

	def call(history,info, opts \\ []) do
		#IO.puts("openai call")  # Logging when the server call is made
		#raise('we should have seen a print')
	    %{
	      "model" => @model,
	      "messages" => Enum.concat([
	        %{"role" => "system", "content" => generate_prompt(info)},
	      ], history),
	      "temperature" => 0.7
	    }
	    |> Jason.encode!()
	    |> request(opts)
	    |> IO.inspect(label: "OpenAi Text")
	    |> parse_response()
	end

  defp parse_response({:ok, %Finch.Response{body: body}}) do
    messages =
      Jason.decode!(body)
      |> Map.get("choices", [])
      |> Enum.reverse()

      |> IO.inspect(label: "OpenAi Messages")

    case messages do
      [%{"message" => message}|_] -> message
      _ -> "{}"
    end
  end

  defp parse_response(error) do
    error
  end

  defp request(body, _opts) do
	  IO.puts("requesting")
	  
	  response = 
	    Finch.build(:post, "https://api.openai.com/v1/chat/completions", headers(), body)
	    |> Finch.request(AiAssistant.Finch, receive_timeout: 120_000) #long wait time are expected source https://community.openai.com/t/slow-response-time-with-gpt-4/107104
	  
	  IO.inspect(response, label: "Response")
	  
	  case response do
	    {:ok, _} -> 
	      response
	      
	    {:error, %Finch.Error{reason: reason}} ->
	      # Log the error reason for Finch errors
	      IO.inspect({"Finch Error", reason}, label: "Error")
	      {:error, reason}
	      
	    {:error, reason} ->
	      # Log for other errors
	      IO.inspect({"Other Error", reason}, label: "Error")
	      {:error, reason}
	  end
	end


  defp headers do
    [
      {"Content-Type", "application/json"},
      {"Authorization", "Bearer #{Application.get_env(:ai_assistant, :open_ai_api_key)}"},
      #{"Authorization", "Bearer #{@api_key}"},
    ]
  end
end