require 'test_helper'

class GigTest < ActiveSupport::TestCase
  def build_gig(skill_list:)
    Gig.new(name: "Logo design", description: "A logo for a bakery.", budget: 100,
            location: "Remote", category: categories(:web_development),
            user: users(:client), skill_list: skill_list)
  end

  # create_skills

  test "creates skills from a comma-separated list, stripped, downcased and de-duplicated" do
    gig = build_gig(skill_list: " Ruby, rails ,RUBY,  JavaScript")
    gig.save!
    assert_equal %w[javascript rails ruby], gig.skills.pluck(:name).sort
  end

  test "reuses existing skills instead of creating duplicates" do
    existing = Skill.create!(name: "ruby")
    gig = build_gig(skill_list: "Ruby")
    assert_no_difference "Skill.count" do
      gig.save!
    end
    assert_equal [existing], gig.skills.to_a
  end

  test "replaces skills when the skill list is updated" do
    gig = build_gig(skill_list: "ruby, rails")
    gig.save!
    gig.update!(skill_list: "python")
    assert_equal %w[python], gig.reload.skills.pluck(:name)
  end

  test "saves a gig without a skill list and gives it no skills" do
    gig = build_gig(skill_list: nil)
    assert gig.save
    assert_empty gig.skills
  end

  test "ignores empty entries in the skill list" do
    gig = build_gig(skill_list: "ruby, , rails,,")
    assert gig.save
    assert_equal %w[rails ruby], gig.skills.pluck(:name).sort
  end

  test "splits skills on new lines, including Windows line endings" do
    gig = build_gig(skill_list: "Ruby\nRails\r\nPostgreSQL")
    gig.save!
    assert_equal %w[postgresql rails ruby], gig.skills.pluck(:name).sort
  end

  test "splits skills on semicolons" do
    gig = build_gig(skill_list: "ruby;rails ; sql")
    gig.save!
    assert_equal %w[rails ruby sql], gig.skills.pluck(:name).sort
  end

  test "splits skills on a mix of commas, semicolons and new lines" do
    gig = build_gig(skill_list: "ruby, rails\nsql; css")
    gig.save!
    assert_equal %w[css rails ruby sql], gig.skills.pluck(:name).sort
  end

  test "keeps multi-word skills together and collapses inner whitespace" do
    gig = build_gig(skill_list: "Ruby   on  Rails, machine\tlearning")
    gig.save!
    assert_equal ["machine learning", "ruby on rails"], gig.skills.pluck(:name).sort
  end

  test "treats a list of only separators and whitespace as no skills" do
    gig = build_gig(skill_list: " ,; \n\r\n , ")
    assert gig.save
    assert_empty gig.skills
  end

  test "treats an empty skill list as no skills" do
    gig = build_gig(skill_list: "")
    assert gig.save
    assert_empty gig.skills
  end

  # search

  test "search by category returns only gigs in that category" do
    results = Gig.search(category: categories(:writing).id.to_s)
    assert_equal [gigs(:blog_posts)], results.to_a
  end

  test "search by keyword matches name, description, location and skills" do
    assert_includes Gig.search(search: "landing"), gigs(:landing_page)
    assert_includes Gig.search(search: "gardening"), gigs(:blog_posts)
    assert_includes Gig.search(search: "Berlin"), gigs(:blog_posts)
    assert_includes Gig.search(search: "copywriting"), gigs(:blog_posts)
    assert_not_includes Gig.search(search: "gardening"), gigs(:landing_page)
  end

  test "search with no category or keyword returns all gigs as a chainable relation" do
    results = Gig.search({})
    assert_kind_of ActiveRecord::Relation, results
    assert_equal Gig.count, results.count
  end

  test "search raises for controller params, which must be permitted first" do
    params = ActionController::Parameters.new(search: "landing")
    assert_raises(ArgumentError) { Gig.search(params) }
  end

  test "search accepts string keys" do
    assert_equal [gigs(:blog_posts)], Gig.search("category" => categories(:writing).id.to_s).to_a
    assert_equal [gigs(:landing_page)], Gig.search("search" => "landing").to_a
  end

  test "search accepts an integer category id" do
    assert_equal [gigs(:blog_posts)], Gig.search(category: categories(:writing).id).to_a
  end

  test "search with an unknown or non-numeric category returns no gigs" do
    assert_empty Gig.search(category: "0")
    assert_empty Gig.search(category: "not-a-number")
  end

  test "search with nil returns all gigs" do
    assert_equal Gig.count, Gig.search(nil).count
  end

  test "search with a whitespace-only keyword returns all gigs" do
    assert_equal Gig.count, Gig.search(search: "   ").count
  end

  test "search strips whitespace around the keyword" do
    assert_equal [gigs(:landing_page)], Gig.search(search: "  landing  ").to_a
  end

  test "search treats SQL wildcard characters literally" do
    assert_empty Gig.search(search: "%")
    assert_empty Gig.search(search: "_")
  end

  test "search raises for params that are not a hash" do
    assert_raises(ArgumentError) { Gig.search("landing") }
    assert_raises(ArgumentError) { Gig.search(["landing"]) }
  end
end
