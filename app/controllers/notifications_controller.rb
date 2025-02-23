class NotificationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user, only: %i[index clear]
  before_action :set_notification, only: [:mark_as_read]

  # Show all notifications for a user
  def index
    @notifications = @user.notifications.order(created_at: :desc)
  end

  # Mark a single notification as read
  def mark_as_read
    @notification.update(read: true)
    redirect_to request.referer || user_notifications_path(current_user)
  end

  # Clear all notifications for a user
  def clear
    @user.notifications.destroy_all
    redirect_to user_notifications_path(@user), notice: "Notifications cleared."
  end

  private
    def set_user
      @user = User.find(params[:user_id])
      redirect_to root_path, alert: "Not authorized." unless @user == current_user
    end

    def set_notification
      @notification = Notification.find(params[:id])
      redirect_to root_path, alert: "Not authorized." unless @notification.user == current_user
    end
end
