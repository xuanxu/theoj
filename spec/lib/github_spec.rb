describe "Github methods" do
  subject do
    repository = "openjournals/reviews"
    issue_id = 33
    token = "1234ABCD"
    Theoj::ReviewIssue.new(repository, issue_id, token)
  end

  describe "#github_client" do
    it "should memoize an Octokit Client" do
      expect(Octokit::Client).to receive(:new).once.and_return("whatever")
      subject.github_client
      subject.github_client
    end
  end

  describe "#github_headers" do
    it "should memoize the GitHub API headers" do
      expected_headers = { "Authorization" => "token 1234ABCD",
                          "Content-Type" => "application/json",
                          "Accept" => "application/vnd.github.v3+json" }

      expect(subject).to receive(:github_access_token).once.and_return("1234ABCD")
      subject.github_headers
      expect(subject.github_headers).to eq(expected_headers)
    end
  end

  describe "#issue" do
    it "should call proper issue using the Octokit client" do
      expect_any_instance_of(Octokit::Client).to receive(:issue).once.with("openjournals/reviews", 33).and_return("issue")
      subject.issue(subject.repository, subject.issue_id)
      subject.issue(subject.repository, subject.issue_id)
    end
  end

  describe "#issue_labels" do
    it "should return the labels names from github issue" do
      labels = [{id:1, name: "A"}, {id:21, name: "J"}]
      expect_any_instance_of(Octokit::Client).to receive(:labels_for_issue).once.with("openjournals/reviews", 33).and_return(labels)
      expect(subject.issue_labels(subject.repository, subject.issue_id)).to eq(["A", "J"])
    end
  end

  describe "#is_collaborator?" do
    it "should be true if user is a collaborator" do
      expect_any_instance_of(Octokit::Client).to receive(:collaborator?).twice.with("openjournals/reviews", "xuanxu").and_return(true)
      expect(subject.is_collaborator?(subject.repository, "@xuanxu")).to eq(true)
      expect(subject.is_collaborator?(subject.repository, "xuanxu")).to eq(true)
    end

    it "should be false if user is not a collaborator" do
      expect_any_instance_of(Octokit::Client).to receive(:collaborator?).twice.with("openjournals/reviews", "xuanxu").and_return(false)
      expect(subject.is_collaborator?(subject.repository, "@XuanXu")).to eq(false)
      expect(subject.is_collaborator?(subject.repository, "xuanxu")).to eq(false)
    end
  end

  describe "#is_invited?" do
    before do
      invitations = [OpenStruct.new(invitee: OpenStruct.new(login: "Rev13w3r")), OpenStruct.new(invitee: OpenStruct.new(login: "4uth0r"))]
      allow_any_instance_of(Octokit::Client).to receive(:repository_invitations).with("openjournals/reviews").and_return(invitations)
    end

    it "should be true if user has a pending invitation" do
      expect(subject.is_invited?(subject.repository, "@REV13w3r")).to eq(true)
      expect(subject.is_invited?(subject.repository, "Rev13w3r")).to eq(true)
    end

    it "should be false if user has not a pending invitation" do
      expect(subject.is_invited?(subject.repository, "stranger")).to eq(false)
    end
  end

  describe "#can_be_assignee?" do
    it "should check if user can be an assignee of the repo" do
      expect_any_instance_of(Octokit::Client).to receive(:check_assignee).once.with("openjournals/reviews", "user21")
      subject.can_be_assignee?(subject.repository, "user21")
    end
  end

  describe "#user_login" do
    it "should remove the @ from a username" do
      expect(subject.user_login("@jossbot")).to eq("jossbot")
    end

    it "should downcase the username" do
      expect(subject.user_login("@JOSSBot")).to eq("jossbot")
    end

    it "should strip the username" do
      expect(subject.user_login(" Jossbot  ")).to eq("jossbot")
    end
  end

  describe "#username?" do
    it "should be true if username starts with @" do
      expect(subject.username?("@jossbot")).to be_truthy
    end

    it "should be false otherwise" do
      expect(subject.username?("jossbot")).to be_falsey
    end
  end
end