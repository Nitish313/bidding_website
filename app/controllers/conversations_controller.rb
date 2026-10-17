class ConversationsController < ApplicationController
  before_action :logged_in_user
  before_action :correct_user
  before_action :own_account_only, except: [:index, :show]
  before_action :set_conversation, only: [:show, :mark_as_read, :destroy]

  def index
    @conversations = Conversation.visible_to(@user).includes(:users, messages: :sender)
    @unread_ids = Conversation.unread_by(@user).ids.to_set
  end

  def new
    @recipients = User.all - [@user]
  end

  def create
    recipient = User.find(params.expect(:receiver_id))
    problem = problem_starting_conversation_with(recipient)
    return refuse_new_conversation(problem) if problem

    message = Conversation.start(sender: @user, recipient: recipient, subject: params[:subject], body: params[:body])
    Notification.create(actor_id: @user.id, receiver_id: recipient.id, action: "started a conversation",
                        notifiable: message)
    redirect_to user_conversation_path(id: message.conversation_id)
  rescue ActiveRecord::RecordInvalid => e
    refuse_new_conversation(e.record.errors.full_messages.to_sentence)
  end

  def show; end

  def mark_as_read
    @conversation.mark_as_read(@user)
    flash[:success] = "The conversation is marked as read."
    redirect_to user_conversations_path
  end

  def destroy
    @conversation.move_to_trash(@user)
    flash[:success] = "Conversation moved to trash."
    redirect_to user_conversations_path
  end

  private

  def problem_starting_conversation_with(recipient)
    return "You can't start a conversation with yourself." if recipient == @user

    "Conversation can't be started without a subject and a body." if params[:subject].blank? || params[:body].blank?
  end

  def refuse_new_conversation(message)
    flash[:danger] = message
    redirect_to new_user_conversation_path
  end

  def set_conversation
    @conversation = Conversation.involving(@user).find(params.expect(:id))
  end
end
