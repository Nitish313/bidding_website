class MessagesController < ApplicationController
  before_action :correct_user
  before_action :set_conversation
  def create
    if params[:body].present?
      receipt = @user.reply_to_conversation(@conversation, params[:body])
      redirect_to user_conversation_path(id: receipt.conversation.id)
    else
      flash[:danger] = "A message reply should have a body"
      redirect_to user_conversations_path
    end
  end

  private

    def set_conversation
      @conversation = @user.mailbox.conversations.find(params[:conversation_id]) 
    end 
end