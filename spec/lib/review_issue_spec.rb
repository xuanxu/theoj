describe Theoj::ReviewIssue do

  before { disable_github_calls }

  before do
    @review_issue  = Theoj::ReviewIssue.new("openjournals/reviews", 42)
    @issue = double(body: "Review Issue 42 \n "+
                         "<!--target-repository-->https://github.com/myorg/researchsoftware<!--end-target-repository-->" +
                         "<!--branch-->paperdocs<!--end-branch-->")
    allow(@review_issue).to receive(:issue).and_return(@issue)
  end

  describe "initialization" do
    it "should create review issue object" do
      repository = "openjournals/reviews"
      issue_id = 33
      token = "1234ABCD"

      review_issue  = Theoj::ReviewIssue.new(repository, issue_id, token)

      expect(review_issue.repository).to eq("openjournals/reviews")
      expect(review_issue.issue_id).to eq(33)
      expect(review_issue.github_access_token).to eq("1234ABCD")
    end
  end

  describe "reading the issue" do
    it "should read issue_body" do
      expect(@review_issue.issue_body).to eq(@issue.body)
    end

    it "should read target_repository" do
      expect(@review_issue.target_repository).to eq("https://github.com/myorg/researchsoftware")
    end

    it "should read paper_branch" do
      expect(@review_issue.paper_branch).to eq("paperdocs")
    end
  end

  describe "paper" do
    it "should return a Paper object from the target repository" do
      expect(Theoj::Paper).to receive(:new).with("https://github.com/myorg/researchsoftware", "paperdocs").and_return("ThePaper")

      expect(@review_issue.paper).to eq("ThePaper")
    end
  end
end
