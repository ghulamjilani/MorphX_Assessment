# frozen_string_literal: true

module MessagesHelper
  def participants_list(users, conversation)
    def presenter_or_regular_user(user)
      link_to user.public_display_name, user.relative_path
    end

    case @box
    when 'sentbox'
      conversation_participants = users - [current_user]
      if conversation_participants.size > 1
        raise "code is not ready for conversations between 3+ participants - #{conversation_participants.inspect}"
      end

      "Recipient: #{presenter_or_regular_user(conversation_participants.first)}".html_safe
    when 'inbox'
      conversation_participants = users - [current_user]
      if conversation_participants.size > 1
        raise "code is not ready for conversations between 3+ participants - #{conversation_participants.inspect}"
      end

      "Sender: #{presenter_or_regular_user(conversation_participants.first)}".html_safe
    when 'trash'
      conversation_participants = users - [current_user]
      if conversation_participants.size > 1
        raise "code is not ready for conversations between 3+ participants - #{conversation_participants.inspect}"
      end

      title = (conversation.originator == 'current_user') ? 'Recipient' : 'Sender'
      "#{title}: #{presenter_or_regular_user(conversation_participants.first)}".html_safe
    else
      raise "can not interpet - #{@box}"
    end
  end

  def formatted_body(text, length = nil)
    if length.present?
      truncate Nokogiri::HTML.parse(text).inner_text, length: length
    else
      simple_format text
    end
  end
end
