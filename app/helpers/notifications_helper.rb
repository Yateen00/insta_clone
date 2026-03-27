module NotificationsHelper
  def notification_message(notification)
    case notification.notifiable
    when Like
      like = notification.notifiable
      if like.likeable.is_a?(Post)
        (link_to "#{like.user.username} liked your post", post_path(like.likeable),
                 class: "text-green-400 font-bold").html_safe
      else
        (link_to "#{like.user.username} liked your comment", post_path(like.likeable, anchor: "comment_#{like.likeable.id}"),
                 class: "text-green-400 font-bold").html_safe
      end
    when Comment
      comment = notification.notifiable
      if comment.reply_to.nil?
        (link_to "#{comment.user.username} commented on your post", post_path(comment.post, anchor: "comment_#{comment.id}"),
                 class: "text-green-400 font-bold").html_safe
      else
        (link_to "#{comment.user.username} replied to your comment", post_path(comment.post, anchor: "comment_#{comment.id}"),
                 class: "text-green-400 font-bold").html_safe
      end
    when Follow
      follow = notification.notifiable
      (link_to "#{follow.follower.username} started following you", user_path(follow.follower),
               class: "text-green-400 font-bold").html_safe
    else
      "New notification"
    end
  end
end
