class ConversationsController < ApplicationController
  before_action :logged_in_user
  before_action :correct_user
  before_action :own_account_only, except: [:index, :show]
  
  def index
    @conversations = @user.mailbox.conversations(mailbox_type: "not_trash")
  end 

  def new
    @recipients = User.all - [@user] 
  end

  def create
    recipient = User.find(params[:receiver_id])
    if recipient == @user
      flash[:danger] = "You can't start a conversation with yourself."
      redirect_to new_user_conversation_path
    elsif params[:body].present? && params[:subject].present?
      receipt = @user.send_message(recipient, params[:body], params[:subject])
      Notification.create(actor_id: @user.id, receiver_id: recipient.id, action: 'started a conversation', notifiable: receipt)
      redirect_to user_conversation_path(id: receipt.conversation.id)
    else
      flash[:danger] = "Conversation can't be started without a subject and a body."
      redirect_to new_user_conversation_path
    end
  end 

  def show
    @conversation = @user.mailbox.conversations.find(params[:id])
  end

  def mark_as_read
    @conversation = @user.mailbox.conversations.find(params[:id])
    @conversation.mark_as_read(@user)
    flash[:success] = 'The conversation is marked as read.'
    redirect_to user_conversations_path
  end

  def destroy
    @conversation = @user.mailbox.conversations.find(params[:id])
    @conversation.move_to_trash(@user)
    flash[:success] = "Conversation moved to trash."
    redirect_to user_conversations_path
  end
end  