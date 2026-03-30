class PresenceChannel < ApplicationCable::Channel
  def subscribed
    reject unless current_user
    stream_from "presence"
  end
end
