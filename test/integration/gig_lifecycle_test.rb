require "test_helper"

# One gig from start to finish, driven through the app's own routes by two people who
# sign up during the test, each in their own browser session: a client posts a gig, a
# freelancer bids, the client awards the bid, they message each other, and the
# freelancer delivers the work.
class GigLifecycleTest < ActionDispatch::IntegrationTest
  setup { ActionMailer::Base.deliveries.clear }

  def sign_up_and_activate(email:, **attributes)
    browser = open_session
    browser.post signup_path, params: {
      user: { email: email, password: "s3cret-pass", password_confirmation: "s3cret-pass",
              profile_picture: fixture_file_upload("avatar.png", "image/png"), **attributes }
    }
    user = User.find_by!(email: email)
    browser.get ActionMailer::Base.deliveries.last.text_part.decoded[%r{http://\S+/account_activations/\S+}]
    browser.assert_redirected_to user_path(user)
    assert_predicate user.reload, :activated?
    [browser, user]
  end

  def actions_notified_to(user)
    Notification.where(receiver: user).order(:id).pluck(:action)
  end

  test "a gig goes from posting through bidding, award and messages to a delivered solution" do
    client_browser, client = sign_up_and_activate(email: "carla@example.com", name: "Carla Client",
                                                  role: "Client", industry: "Retail")
    freelancer_browser, freelancer = sign_up_and_activate(email: "fred@example.com", name: "Fred Freelancer",
                                                          role: "Freelancer", industry: "Software",
                                                          education: "BSc", experience: 4)

    # The client posts a gig.
    client_browser.post gigs_path, params: {
      gig: { name: "Shop landing page", description: "A one-page site for our shop.", budget: 500,
             location: "Remote", category_id: categories(:web_development).id, skill_list: "HTML, CSS" }
    }
    gig = Gig.find_by!(name: "Shop landing page")
    client_browser.assert_redirected_to gig_path(gig)
    assert_equal client, gig.user
    assert_equal %w[css html], gig.skills.map(&:name).sort

    # The freelancer finds it by searching and bids on it; the client is notified.
    freelancer_browser.get search_gigs_path, params: { search: "landing" }
    freelancer_browser.assert_select "a[href=?]", gig_path(gig)
    freelancer_browser.post gig_proposals_path(gig), params: {
      proposal: { name: "Fred's bid", bid: 450, description: "Done within a week." }
    }
    proposal = gig.proposals.find_by!(user: freelancer)
    assert_equal ["proposed"], actions_notified_to(client)
    assert_empty actions_notified_to(freelancer)

    # Work can't be delivered before the award.
    freelancer_browser.post proposal_solutions_path(proposal), params: {
      solution: { name: "Early draft", attachment_1: fixture_file_upload("solution.txt", "text/plain") }
    }
    freelancer_browser.assert_redirected_to proposal_path(proposal)
    assert_equal "You can submit solutions only after this proposal is awarded.", freelancer_browser.flash[:warning]
    assert_empty proposal.solutions

    # The client awards the bid; the freelancer is notified and sees where to deliver.
    client_browser.patch gig_path(gig), params: { gig: { awarded_proposal: proposal.id } }
    client_browser.assert_redirected_to gig_path(gig)
    assert_equal proposal.id, gig.reload.awarded_proposal
    assert_equal ["awarded"], actions_notified_to(freelancer)
    freelancer_browser.get user_notifications_path(freelancer)
    freelancer_browser.assert_select "a[href=?]", proposal_path(proposal), text: "Show this proposal to upload solutions"

    # They talk it over; each message notifies the other side and shows as unread.
    freelancer_browser.post user_conversations_path(freelancer), params: {
      receiver_id: client.id, subject: "Shop landing page", body: "Any brand colours?"
    }
    conversation = Conversation.involving(client).sole
    assert conversation.unread_for?(client)
    client_browser.post mark_as_read_user_conversation_path(client, conversation)
    client_browser.post user_conversation_messages_path(client, conversation), params: { body: "Green and white." }
    assert_equal ["Any brand colours?", "Green and white."], conversation.messages.map(&:body)
    assert_equal ["proposed", "started a conversation"], actions_notified_to(client)
    assert_equal ["awarded", "sent a message"], actions_notified_to(freelancer)
    assert conversation.unread_for?(freelancer)
    assert_not conversation.unread_for?(client)

    # The freelancer delivers the work, and the client can open it.
    freelancer_browser.post proposal_solutions_path(proposal), params: {
      solution: { name: "Final site", attachment_1: fixture_file_upload("solution.txt", "text/plain") }
    }
    freelancer_browser.assert_redirected_to proposal_path(proposal)
    solution = proposal.solutions.sole
    assert_equal gig, solution.gig
    client_browser.get gig_solutions_path(gig)
    client_browser.assert_response :success
    client_browser.assert_select "td", text: "Final site"
    client_browser.assert_select "a[href=?]", solution.attachment_1_url

    # Once awarded, the gig can no longer be deleted.
    assert_no_difference "Gig.count" do
      client_browser.delete gig_path(gig)
    end
    assert_equal "An awarded gig can't be deleted.", client_browser.flash[:danger]
  end
end
