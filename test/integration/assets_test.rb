require "test_helper"

# The asset pipeline builds the JavaScript and CSS bundles the layout links to.
class AssetsTest < ActionDispatch::IntegrationTest
  def asset_body(name)
    get root_path
    path = css_select(name.end_with?(".js") ? "script[src]" : "link[rel=stylesheet]")
           .map { |tag| tag["src"] || tag["href"] }
           .find { |src| src.include?(name.delete_suffix(File.extname(name))) }
    assert path, "the layout does not link #{name}"
    get path
    assert_response :success
    response.body
  end

  test "the JavaScript bundle includes jQuery, Bootstrap and rails-ujs" do
    js = asset_body("application.js")
    assert_match "jQuery", js
    assert_match "bootstrap", js.downcase
    assert_match "data-confirm", js, "rails-ujs handles data-confirm links"
  end

  test "the stylesheet bundle includes Bootstrap and the app's own styles" do
    css = asset_body("application.css")
    assert_match ".navbar", css
    assert_match ".btn", css
  end
end
