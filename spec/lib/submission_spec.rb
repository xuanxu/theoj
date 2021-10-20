describe Theoj::Submission do

  before do
    @journal = Theoj::Journal.new({ alias: "test-journal", doi_prefix: "12.34567" })
    @review_issue = Theoj::ReviewIssue.new("openjournals/reviews", 42)
    @paper = Theoj::Paper.new("repository", "branch", fixture("paper_metadata.md"))

    @submission  = Theoj::Submission.new(@journal, @review_issue, @paper)
  end

  describe "initialization" do
    it "should set journal, review issue and paper" do
      expect(@submission.review_issue).to eq(@review_issue)
      expect(@submission.journal).to eq(@journal)
      expect(@submission.paper).to eq(@paper)
    end

    it "should get paper from review_issue" do
      @review_issue.paper = @paper
      no_paper_submission  = Theoj::Submission.new(@journal, @review_issue)

      expect(no_paper_submission.review_issue).to eq(@review_issue)
      expect(no_paper_submission.journal).to eq(@journal)
      expect(no_paper_submission.paper).to eq(@paper)
    end
  end

  it "should set paper id based on the journal and the review issue id" do
    expect(@submission.paper_id).to eq(@journal.paper_id_from_issue(42))
    expect(@submission.paper_id).to eq("test-journal.00042")
  end

  it "should set paper's doi based on the journal and the paper id" do
    expect(@submission.paper_doi).to eq(@journal.paper_doi_for_id("test-journal.00042"))
    expect(@submission.paper_doi).to eq("12.34567/test-journal.00042")
  end

  it "should create citation_string using journal, review issue and paper information" do
    citation_string = @submission.citation_string

    expect(citation_string).to include(@paper.citation_author)
    expect(citation_string).to include(Time.now.year.to_s)
    expect(citation_string).to include(@paper.title)
    expect(citation_string).to include(@journal.name)
    expect(citation_string).to include(@journal.current_volume.to_s)
    expect(citation_string).to include(@journal.current_issue.to_s)
    expect(citation_string).to include(@review_issue.issue_id.to_s)
    expect(citation_string).to include(@submission.paper_doi)
  end

  describe "payloads" do

    before do
      issue = double(body: "Review Issue 42 \n "+
                           "<!--target-repository-->https://github.com/myorg/researchsoftware<!--end-target-repository-->" +
                           "<!--branch-->paperdocs<!--end-branch-->" +
                           "<!--editor-->@the-editor <!--end-editor-->" +
                           "<!--reviewers--> @reviewer1, reviewer2<!--end-reviewers-->" +
                           "<!--version-->1.33.42<!--end-version-->" +
                           "<!--archive-->link-to-zenodo<!--end-archive-->" +
                           "<!--whatever-->nevermind<!--end-whatever-->" +
                           "<!--no-value-->Pending<!--end-no-value-->")
      allow(@review_issue).to receive(:issue).and_return(issue)
    end

    it "should create a metadata json payload" do
      json_payload = @submission.metadata_payload
      payload = JSON.parse json_payload

      expect(payload['paper'].keys.size).to eq(13)

      payload['paper'].values.each do |value|
        expect(value).to_not be_nil
        expect(value.to_s).to_not be_empty
      end

      expect(payload['paper']['title']).to eq(@paper.title)
      expect(payload['paper']['tags']).to eq(@paper.tags)
      expect(payload['paper']['languages']).to eq(@paper.languages)
      expect(payload['paper']['authors']).to eq(JSON.parse(@paper.authors.collect { |a| a.to_h }.to_json))
      expect(payload['paper']['doi']).to eq(@submission.paper_doi)
      expect(payload['paper']['archive_doi']).to eq("link-to-zenodo")
      expect(payload['paper']['repository_address']).to eq("https://github.com/myorg/researchsoftware")
      expect(payload['paper']['editor']).to eq("@the-editor")
      expect(payload['paper']['reviewers']).to eq(["@reviewer1", "reviewer2"])
      expect(payload['paper']['volume']).to eq(@journal.current_volume)
      expect(payload['paper']['issue']).to eq(@journal.current_issue)
      expect(payload['paper']['year']).to eq(@journal.current_year)
      expect(payload['paper']['page']).to eq(42)
    end

    it "should create a valid Open Journals deposit payload" do
      payload = @submission.deposit_payload

      expect(payload[:id]).to eq(42)
      expect(payload[:metadata]).to eq(Base64.encode64(@submission.metadata_payload))
      expect(payload[:doi]).to eq(@submission.paper_doi)
      expect(payload[:archive_doi]).to eq("link-to-zenodo")
      expect(payload[:citation_string]).to eq(@submission.citation_string)
      expect(payload[:title]).to eq(@paper.title)
    end
  end
end
