require "test_helper"

class LearnTopicsControllerTest < ActionDispatch::IntegrationTest
  setup { @topic = LearnTopic.find("system-design-in-8-weeks") }

  def json_ld
    css_select("script[type='application/ld+json']").map { |node| JSON.parse(node.text) }
  end

  test "the index lists every study plan" do
    get learn_topics_path

    assert_response :success
    assert_select "h1", "Study plans for developers"
    LearnTopic.all.each { |topic| assert_select "a[href=?]", learn_topic_path(topic), text: topic.title }
  end

  test "a topic page is indexable with its own title, description, canonical and week-by-week steps" do
    get learn_topic_path(@topic)

    assert_response :success
    assert_select "title", "#{@topic.title} | Path Aviator"
    assert_select "meta[name=description][content=?]", @topic.description
    assert_select "link[rel=canonical][href=?]", learn_topic_url(@topic)
    assert_select "meta[name=robots]", count: 0
    assert_nil response.headers["X-Robots-Tag"]
    assert_select "h3", "Week 1"
    @topic.steps.each { |step| assert_select "a[href=?][rel=noopener]", step.url }
    assert_select "a[href=?]", new_registration_path(learn: @topic.slug), text: "Make this plan mine"
  end

  test "a topic page carries Course and ItemList structured data" do
    get learn_topic_path(@topic)

    graph = json_ld.sole["@graph"]
    course = graph.find { |node| node["@type"] == "Course" }
    list = graph.find { |node| node["@type"] == "ItemList" }
    assert_equal @topic.title, course["name"]
    assert_equal "Path Aviator", course.dig("provider", "name")
    assert_equal @topic.steps.size, list["itemListElement"].size
    assert_equal({ "@type" => "ListItem", "position" => 1, "name" => @topic.steps.first.title, "url" => @topic.steps.first.url },
                 list["itemListElement"].first)
  end

  test "an unknown topic is a 404" do
    get learn_topic_path("not-a-topic")
    assert_response :not_found
  end

  test "signed in, make this mine copies the plan and opens it" do
    sign_in_as users(:two)
    get learn_topic_path(@topic)
    assert_select "form[action=?] button", copy_learn_topic_path(@topic), text: "Make this plan mine"

    assert_difference -> { users(:two).learning_paths.count } => 1 do
      post copy_learn_topic_path(@topic)
    end
    assert_redirected_to learning_path_path(users(:two).learning_paths.order(:id).last)
  end

  test "guests sign up and get the plan straight away" do
    post copy_learn_topic_path(@topic)
    assert_redirected_to new_session_path

    get new_registration_path(learn: @topic.slug)
    assert_select "input[type=hidden][name=learn][value=?]", @topic.slug

    post registration_path, params: { learn: @topic.slug,
      user: { email_address: "learner@example.com", password: "long-enough-pw", password_confirmation: "long-enough-pw" } }

    user = User.find_by!(email_address: "learner@example.com")
    assert_redirected_to learning_path_path(user.learning_paths.sole)
    assert_equal @topic.title, user.learning_paths.sole.title
  end
end
