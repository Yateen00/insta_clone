module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = find_verified_user
      current_user.update(online: true)
      ActionCable.server.broadcast(
        "presence",
        { user_id: current_user.id, online: true }
      )
    end

    def disconnect
      return unless current_user

      current_user.update(online: false)
      ActionCable.server.broadcast(
        "presence",
        { user_id: current_user.id, online: false }
      )
    end

    private
      def find_verified_user
        env["warden"].user || reject_unauthorized_connection
      end
  end
end
