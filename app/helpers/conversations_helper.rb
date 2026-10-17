module ConversationsHelper
  # Links to a user's profile, or says "Deleted user" when the account no longer exists.
  def link_to_user_or_deleted(user)
    user ? link_to(user.name, user_path(user)) : "Deleted user"
  end
end
