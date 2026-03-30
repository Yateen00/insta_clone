class ChatRoom < ApplicationRecord
  enum :kind, { group: 0, dm: 1 }, default: :dm

  has_many :chat_members, dependent: :destroy
  has_many :users, through: :chat_members
  has_many :messages, dependent: :destroy
  # Returns a hash for API responses, customized for the current user
  def as_api_json(current_user, include_messages: false)
    # Use Ruby's find to avoid hitting the DB if chat_members is eager-loaded
    member = chat_members.to_a.find { |m| m.user_id == current_user.id }

    if kind == "group" && member.nil?
      {
        id: id,
        name: name,
        kind: kind,
        member_count: users.length,
        is_member: false
      }
    else
      # Use Ruby's select instead of .where to utilize eager loading and prevent N+1 queries
      loaded_users = users.to_a
      online_users = loaded_users.select(&:online)

      # Determine chat display name for DMs automatically if name is blank
      display_name = name
      if kind == "dm" && name.blank?
        other_user = loaded_users.find { |u| u.id != current_user.id }
        display_name = other_user&.username || "Unknown User"
      end

      data = {
        id: id,
        name: display_name,
        kind: kind,
        is_member: true,
        users: loaded_users.as_json(only: %i[id username online]),
        unread_count: member&.unread_messages_count || 0,
        # Use max on the ruby array to prevent N+1 or use the eager-loaded messages
        last_message_at: messages.to_a.max_by(&:created_at)&.created_at,
        online_count: online_users.length,
        online_members: online_users.as_json(only: %i[id username online]),
        created_at: created_at
      }

      if include_messages
        data[:messages] = messages.includes(:user, :content).map do |m|
          m.as_json(include: { user: { only: %i[id username] }, content: {} })
        end
      end

      data
    end
  end
end
