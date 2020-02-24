class ConversationsController < ApplicationController
  before_action :logged_in_user
  
  def index
    @conversations = current_user.mailbox.conversations
  end 

  def new
    @recipients = User.all - [current_user] 
  end

  def create
    recipient = User.find(params[:user_id])
    receipt = current_user.send_message(
                  recipient, params[:body], params[:subject]
                )
    redirect_to conversation_path(receipt.conversation)
  end 

  def show
    @recipient = User.find(params[:user_id])
    @conversation = current_user.mailbox.conversations.find(params[:id])
  end

  def mark_as_read
    @conversation = current_user.mailbox.conversations.find(params[:id])
    @conversation.mark_as_read(current_user)
    flash[:success] = 'The conversation was marked as read.'
    redirect_to conversations_path
  end

  def destroy
    @conversation = current_user.mailbox.conversations.find(params[:id])
    @conversation.destroy
    flash[:success] = "Conversation deleted successfully."
    redirect_to conversations_path
  end
end  