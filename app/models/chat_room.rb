class ChatRoom < ApplicationRecord
  enum :kind, { group: 0, dm: 1 }, default: :dm, prefix: true

  has_many :chat_members, dependent: :destroy
  has_many :users, through: :chat_members
  has_many :messages, dependent: :destroy
  # Returns a hash for API responses, customized for the current user
  def as_api_json(current_user, include_messages: false, unread_count: nil, last_message_at: nil)
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

      # Use precalculated counts if provided, otherwise fetch (fallback)
      calculated_unread = unread_count || member&.unread_messages_count || 0
      # Use precalculated timestamp if provided, otherwise find max from room collection
      latest_time = last_message_at || messages.to_a.max_by(&:created_at)&.created_at

      data = {
        id: id,
        name: display_name,
        kind: kind,
        is_member: true,
        users: loaded_users.as_json(only: %i[id username online]),
        unread_count: calculated_unread,

        last_message_at: latest_time,
        online_count: online_users.length,
        member_count: loaded_users.length,
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

  # Seamlessly joins a user to the room IF it's a public group
  def join_user!(user)
    return if kind != "group" || chat_members.exists?(user_id: user.id)

    chat_members.create!(user: user)
    # Notify the user's other devices that they've joined a new room
    ActionCable.server.broadcast("user_#{user.id}_channel", {
      event: "group_added",
      room: as_api_json(user)
    })
  end
end
