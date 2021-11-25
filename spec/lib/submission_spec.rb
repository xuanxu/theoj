describe Theoj::Submission do

  before do
    @journal = Theoj::Journal.new({ alias: "test-journal", doi_prefix: "12.34567" })
    @review_issue = Theoj::ReviewIssue.new("openjournals/reviews", 42)
    @paper = Theoj::Paper.new("repository", "branch", fixture("paper_metadata.md"))

    @submission  = Theoj::Submission.new(@journal, @review_issue, @paper)

    issue = double(body: "Review Issue 42 \n "+
                         "<!--target-repository-->https://github.com/myorg/researchsoftware<!--end-target-repository-->" +
                         "<!--branch-->paperdocs<!--end-branch-->" +
                         "<!--editor-->@the-editor <!--end-editor-->" +
                         "<!--reviewers-list--> @reviewer1, reviewer2<!--end-reviewers-list-->" +
                         "<!--version-->1.33.42<!--end-version-->" +
                         "<!--archive-->link-to-zenodo<!--end-archive-->" +
                         "<!--whatever-->nevermind<!--end-whatever-->" +
                         "<!--no-value-->Pending<!--end-no-value-->")
    allow(@review_issue).to receive(:issue).and_return(issue)
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

  describe "#article_metadata" do
    before do
      editor_lookup = double(status: 200, body: { name: "J.B.", url: "http://editor.edit", orcid: "007" }.to_json)
      paper_lookup = double(status: 200, body: { submitted: "24 Nov 2022", accepted: "25 Nov 2022" }.to_json)
      expect(Faraday).to receive(:get).with("https://joss.theoj.org/editors/lookup/the-editor").and_return(editor_lookup)
      expect(Faraday).to receive(:get).with("https://joss.theoj.org/papers/lookup/42").and_return(paper_lookup)

      @article_metadata = @submission.article_metadata
    end

    it "should include article metadata" do
      expect(@article_metadata.keys.size).to eq(17)

      expect(@article_metadata[:title]).to eq(@paper.title)
      expect(@article_metadata[:tags]).to eq(@paper.tags)
      expect(@article_metadata[:authors]).to eq(@paper.authors.collect { |a| a.to_h })
      expect(@article_metadata[:doi]).to eq(@submission.paper_doi)
      expect(@article_metadata[:software_repository_url]).to eq("https://github.com/myorg/researchsoftware")
      expect(@article_metadata[:reviewers]).to eq(["@reviewer1", "reviewer2"])
      expect(@article_metadata[:volume]).to eq(@journal.current_volume)
      expect(@article_metadata[:issue]).to eq(@journal.current_issue)
      expect(@article_metadata[:year]).to eq(@journal.current_year)
      expect(@article_metadata[:journal_alias]).to eq(@journal.alias)
      expect(@article_metadata[:page]).to eq(42)
      expect(@article_metadata[:software_review_url]).to eq(@journal.reviews_repository_url(42))
      expect(@article_metadata[:archive_doi]).to eq("link-to-zenodo")
      expect(@article_metadata[:citation_string]).to eq(@submission.citation_string)
    end

    it "should include editor information" do
      expect(@article_metadata[:editor]).to eq({ github_user: "@the-editor",
                                                 name: "J.B.",
                                                 url: "http://editor.edit",
                                                 orcid: "007" })
    end

    it "should include submitted_at/published_at data" do
      expect(@article_metadata[:submitted_at]).to eq("2022-11-24")
      expect(@article_metadata[:published_at]).to eq("2022-11-25")
    end

    it "should include nil information from lookups if not available" do
      editor_lookup = double(status: 404)
      paper_lookup = double(status: 500)

      expect(Faraday).to receive(:get).with("https://joss.theoj.org/editors/lookup/the-editor").and_return(editor_lookup)
      expect(Faraday).to receive(:get).with("https://joss.theoj.org/papers/lookup/42").and_return(paper_lookup)

      article_metadata = @submission.article_metadata

      expect(article_metadata[:editor]).to eq({ github_user: "@the-editor",
                                                name: nil,
                                                url: nil,
                                                orcid: nil })
      expect(article_metadata[:submitted_at]).to eq(nil)
      expect(article_metadata[:published_at]).to eq(nil)
    end
  end

  describe "#editor_info" do
    it "should lookup editor" do
      editor_lookup = double(status: 200, body: { name: "J.B.", url: "http://editor.edit", orcid: "007" }.to_json)
      expect(Faraday).to receive(:get).with("https://joss.theoj.org/editors/lookup/the-editor").and_return(editor_lookup)

      editor_info = @submission.editor_info
      expect(editor_info[:editor]).to eq({ github_user: "@the-editor", name: "J.B.", url: "http://editor.edit", orcid: "007" })
    end

    it "should default to empty values" do
      expect(Faraday).to receive(:get).with("https://joss.theoj.org/editors/lookup/the-editor").and_return(double(status: 403))

      editor_info = @submission.editor_info
      expect(editor_info[:editor]).to eq({ github_user: "@the-editor", name: nil, url: nil, orcid: nil })
    end
  end

  describe "#dates_info" do
    it "should lookup paper" do
      paper_lookup = double(status: 200, body: { submitted: "30 April 2022", accepted: "1 November 2022" }.to_json)
      expect(Faraday).to receive(:get).with("https://joss.theoj.org/papers/lookup/42").and_return(paper_lookup)

      dates_info = @submission.dates_info
      expect(dates_info).to eq({ submitted_at: "2022-04-30", published_at: "2022-11-01" })
    end

    it "should default to empty values" do
      expect(Faraday).to receive(:get).with("https://joss.theoj.org/papers/lookup/42").and_return(double(status: 500))

      dates_info = @submission.dates_info
      expect(dates_info).to eq({ submitted_at: nil, published_at: nil})
    end

    it "should return nil for invalid date values" do
      paper_lookup = double(status: 200, body: { submitted: "Invalid date", accepted: "61 November 2222" }.to_json)
      expect(Faraday).to receive(:get).with("https://joss.theoj.org/papers/lookup/42").and_return(paper_lookup)

      dates_info = @submission.dates_info
      expect(dates_info).to eq({ submitted_at: nil, published_at: nil})
    end
  end

  describe "#deposit!" do
    it "should call the journal's deposit url" do
      expected_url = @journal.data[:deposit_url]
      expect(expected_url.to_s).to_not be_empty
      expect(Faraday).to receive(:post).with(expected_url, anything, anything)

      @submission.deposit!("secret")
    end

    it "should include the received secret in the payload" do
      deposit_payload = @submission.deposit_payload
      deposit_payload[:secret] = "journal-secret-token"
      expected_payload = deposit_payload.to_json
      expect(Faraday).to receive(:post).with(anything, expected_payload, anything)

      @submission.deposit!("journal-secret-token")
    end

    it "should return the API call response" do
      expect(Faraday).to receive(:post).and_return(double(body: "OK", status: 201))
      response = @submission.deposit!("secret")

      expect(response.status).to eq(201)
    end
  end

end
