require "test_helper"

class CertificatesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @path = learning_paths(:rails)
    @path.path_steps.each { |step| step.update!(completed_at: 1.day.ago) unless step.completed? }
    @path.reload
  end

  test "publishing needs Pro" do
    sign_in_as users(:one)

    get new_learning_path_certificate_path(@path)
    assert_redirected_to pricing_path

    post learning_path_certificate_path(@path)
    assert_redirected_to pricing_path
    assert_not @path.reload.certificate_published?
  end

  test "Pro users publish a finished path's certificate with evidence links" do
    sign_in_as users(:one)
    step = path_steps(:rails_deploy)

    as_pro do
      get new_learning_path_certificate_path(@path)
      assert_response :success
      assert_select "input[type=url][name=?]", "evidence[#{step.id}]"

      post learning_path_certificate_path(@path), params: { evidence: { step.id => "https://riya.dev/demo" } }
    end

    @path.reload
    assert_redirected_to certificate_path(@path.certificate_token)
    assert_equal "https://riya.dev/demo", step.reload.evidence_url
  end

  test "a bad evidence link re-renders the form and publishes nothing" do
    sign_in_as users(:one)
    step = path_steps(:rails_deploy)

    as_pro { post learning_path_certificate_path(@path), params: { evidence: { step.id => "ftp://nope" } } }

    assert_response :unprocessable_entity
    assert_select "#evidence_#{step.id}[aria-invalid=true]"
    assert_not @path.reload.certificate_published?
  end

  test "an unfinished path or a nameless account can't publish" do
    sign_in_as users(:one)
    path_steps(:rails_deploy).update!(completed_at: nil)

    as_pro { post learning_path_certificate_path(@path) }
    assert_redirected_to learning_path_path(@path)

    path_steps(:rails_deploy).update!(completed_at: Time.current)
    users(:one).update!(name: nil)
    as_pro { post learning_path_certificate_path(@path) }
    assert_redirected_to new_learning_path_certificate_path(@path)
    assert_not @path.reload.certificate_published?
  end

  test "someone else's path is a 404" do
    sign_in_as users(:two)

    as_pro { post learning_path_certificate_path(@path) }
    assert_response :not_found
  end

  test "the public certificate shows the proof, is noindex, and has no owner tools for visitors" do
    @path.publish_certificate!

    get certificate_path(@path.certificate_token)

    assert_response :success
    assert_equal "noindex", response.headers["X-Robots-Tag"]
    assert_select "meta[name=robots][content=noindex]"
    assert_select "p", "Riya Sharma"
    assert_select "h1", @path.title
    assert_select "dd", "4 of 4"
    assert_select "dd", "5 h 15 min"
    assert_select "meta[property='og:title'][content=?]", "Riya Sharma completed “#{@path.title}”"
    assert_select "a[href^='https://www.linkedin.com']", count: 0
    assert_no_match "one@example.com", response.body
    assert_no_match "Redo the blog", response.body, "notes stay private"
  end

  test "the owner gets a LinkedIn Add to profile link with the documented parameters" do
    @path.publish_certificate!
    sign_in_as users(:one)

    get certificate_path(@path.certificate_token)

    link = css_select("a[href^='https://www.linkedin.com/profile/add']").first["href"]
    query = Rack::Utils.parse_query(URI(link).query)
    assert_equal "CERTIFICATION_NAME", query["startTask"]
    assert_equal @path.title, query["name"]
    assert_equal "Path Aviator", query["organizationName"]
    assert_equal @path.certificate_issued_at.year.to_s, query["issueYear"]
    assert_equal @path.certificate_issued_at.month.to_s, query["issueMonth"]
    assert_equal certificate_url(@path.certificate_token), query["certUrl"]
    assert_equal @path.certificate_token, query["certId"]
    assert_includes link, "name=Ruby%20on%20Rails", "spaces are %20, as in LinkedIn's examples"
  end

  test "revoking turns the link off, and so does un-ticking a step" do
    @path.publish_certificate!
    token = @path.certificate_token
    sign_in_as users(:one)

    path_steps(:rails_deploy).update!(completed_at: nil)
    get certificate_path(token)
    assert_response :not_found

    path_steps(:rails_deploy).update!(completed_at: Time.current)
    delete learning_path_certificate_path(@path)
    assert_redirected_to learning_path_path(@path)
    get certificate_path(token)
    assert_response :not_found
  end

  test "a finished path's progress panel offers the certificate to Pro and Pro to everyone else" do
    sign_in_as users(:one)

    get learning_path_path(@path)
    assert_select "a[href=?]", pricing_path, text: "See Pro"

    as_pro { get learning_path_path(@path) }
    assert_select "a[href=?]", new_learning_path_certificate_path(@path), text: "Get your certificate"
  end
end
