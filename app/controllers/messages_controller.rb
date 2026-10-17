class MessagesController < ApplicationController
  before_action :logged_in_user
  before_action :correct_user
  before_action :own_account_only
  before_action :set_conversation

  def create
    if params[:body].present?
      message = @conversation.reply(sender: @user, body: params[:body])
      recipient = @conversation.other_participant(@user)
      Notification.create(actor_id: @user.id, receiver_id: recipient.id, action: "sent a message", notifiable: message) if recipient
      redirect_to user_conversation_path(id: @conversation.id)
    else
      flash[:danger] = "A message reply should have a body"
      redirect_to user_conversations_path
    end
  rescue ActiveRecord::RecordInvalid => e
    flash[:danger] = e.record.errors.full_messages.to_sentence
    redirect_to user_conversation_path(id: @conversation.id)
  end

  private

  def set_conversation
    @conversation = Conversation.involving(@user).find(params.expect(:conversation_id))
  end
end
