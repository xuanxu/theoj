describe Theoj::RetractionNotice do

  describe "initialization" do
    it "should error if invalid journal" do
      expect(Faraday).to_not receive(:get)

      expect{ Theoj::RetractionNotice.new("doi", "invalid_journal")}.to raise_error("Can't find journal invalid_journal")
    end

    it "should error if invalid DOI" do
      expect(Faraday).to receive(:get).with("https://doi.org/wrong-doi").and_return(double(status: 404))

      expect{ Theoj::RetractionNotice.new("wrong-doi", "test_journal")}.to raise_error("The DOI is invalid, url does not resolve https://doi.org/wrong-doi")
    end

    it "should error if paper's metadata can't be found" do
      doi_response = double(status: 302, headers: {location: "paper-url"})
      expect(Faraday).to receive(:get).with("https://doi.org/paper-doi").and_return(doi_response)
      expect(Faraday).to receive(:get).with("paper-url.json").and_return(double(status: 404))


      expect{ Theoj::RetractionNotice.new("paper-doi", "test_journal")}.to raise_error("Could not find the paper data at paper-url.json")
    end

    it "should initialize journal and retracted paper" do
      doi_response = double(status: 302, headers: {location: "paper-url"})
      allow(Faraday).to receive(:get).with("https://doi.org/paper-doi").and_return(doi_response)
      paper_response = double(status: 200, body: { title: "Test paper", doi: "paper-doi", state: "accepted"}.to_json)
      allow(Faraday).to receive(:get).with("paper-url.json").and_return(paper_response)

      expected_retracted_paper_metadata = Theoj::PublishedPaper.new("paper-doi").metadata
      expected_journal_data = Theoj::Journal.new(Theoj::JOURNALS_DATA[:test_journal]).data

      retraction_notice = Theoj::RetractionNotice.new("paper-doi", "test_journal")
      expect(retraction_notice.journal.data).to eq expected_journal_data
      expect(retraction_notice.retracted_paper.metadata).to eq expected_retracted_paper_metadata
    end
  end

  describe "retraction methods" do
    before do
      @metadata = { title: "Test paper",
                    doi: "paper-doi",
                    state: "accepted",
                    volume: "42",
                    issue: "12",
                    year: "33",
                    page: "45678",
                    authors: [{name: "A. Uthor"}],
                    reviewers: ["reviewer1", "reviewer2"],
                    languages: ["Python"],
                    tags: ["tests", "specs"],
                    software_repository: "https://github.com/openjournals/test",
                    paper_review: "https://github.com/openjournals/test_journal/issues/5567",
                    software_archive: "https://doi.org/10.AAAA/zenodo.33",
                  }

      doi_response = double(status: 302, headers: {location: "paper-url"})
      allow(Faraday).to receive(:get).with("https://doi.org/paper-doi").and_return(doi_response)


      paper_response = double(status: 200, body: @metadata.to_json)
      allow(Faraday).to receive(:get).with("paper-url.json").and_return(paper_response)

      @journal = Theoj::Journal.new(Theoj::JOURNALS_DATA[:test_journal])
      @retraction_notice = Theoj::RetractionNotice.new("paper-doi", "test_journal")
    end

    describe "#metadata" do
      it "should generate metadata based on the retracted paper" do
        expected_metadata = {
          title: "Retraction notice for: Test paper",
          tags: ["tests", "specs"],
          authors: [{ given_name: "TEST_JOURNAL",
                      last_name: "Editorial Board",
                      affiliation: "Test Journal"}],
          doi: "paper-doiR",
          software_repository_url: "https://github.com/openjournals/test",
          reviewers: [],
          volume: @journal.current_volume,
          issue: @journal.current_issue,
          year: @journal.current_year,
          page: "45678R",
          journal_alias: "test_journal",
          software_review_url: "https://github.com/openjournals/test_journal/issues/5567",
          archive_doi: "10.AAAA/zenodo.33",
          editor: { github_user: "openjournals", name: "Editorial Board", url: @journal.data[:url] },
          submitted_at: Time.now.strftime("%Y-%m-%d"),
          published_at: Time.now.strftime("%Y-%m-%d")
        }

        expect(@retraction_notice.metadata).to eq(expected_metadata)
      end
    end

    describe "#deposit_payload" do
      it "should create a valid Open Journals deposit payload for retraction" do
        expected_deposit_payload = {
          doi: "paper-doi",
          metadata: Base64.encode64(
            {
              paper: {
                title: "Retraction notice for: Test paper",
                tags: ["tests", "specs"],
                languages: [],
                authors: [{ given_name: "TEST_JOURNAL",
                            last_name: "Editorial Board",
                            affiliation: "Test Journal"}],
                doi: "paper-doiR",
                archive_doi: "10.AAAA/zenodo.33",
                repository_address: "https://github.com/openjournals/test",
                editor: "openjournals",
                reviewers: [],
                volume: @journal.current_volume,
                issue: @journal.current_issue,
                year: @journal.current_year,
                page: "45678R"
              }
            }.to_json
          ),
          citation_string: "Editorial Board, (#{@journal.current_year}). Retraction notice for: Test paper. Test Journal, #{@journal.current_volume}(#{@journal.current_issue}), 45678R, https://doi.org/paper-doiR"
        }

        expect(@retraction_notice.deposit_payload).to eq(expected_deposit_payload)
      end
    end

    it "should create a valid citation string" do
      expect(@retraction_notice.citation_string).to eq "Editorial Board, (#{@journal.current_year}). Retraction notice for: Test paper. Test Journal, #{@journal.current_volume}(#{@journal.current_issue}), 45678R, https://doi.org/paper-doiR"
    end

    describe "#deposit!" do
      it "should call the journal's retract url" do
        expected_url = @journal.data[:retract_url]
        expect(expected_url.to_s).to_not be_empty
        expect(Faraday).to receive(:post).with(expected_url, anything, anything)

        @retraction_notice.deposit!("secret")
      end

      it "should include the received secret in the payload" do
        deposit_payload = @retraction_notice.deposit_payload
        deposit_payload[:secret] = "journal-secret-token"
        expected_payload = deposit_payload.to_json
        expect(Faraday).to receive(:post).with(anything, expected_payload, anything)

        @retraction_notice.deposit!("journal-secret-token")
      end

      it "should return the API call response" do
        expect(Faraday).to receive(:post).and_return(double(body: "OK", status: 201))
        response = @retraction_notice.deposit!("secret")

        expect(response.status).to eq(201)
      end
    end

  end
end
