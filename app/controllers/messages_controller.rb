class MessagesController < ApplicationController
  before_action :correct_user
  before_action :set_conversation
  def create
    receipt = @user.reply_to_conversation(@conversation, params[:body])
    redirect_to user_conversation_path(id: receipt.conversation.id)
  end

  private

    def set_conversation
      @conversation = @user.mailbox.conversations.find(params[:conversation_id]) 
    end 
end