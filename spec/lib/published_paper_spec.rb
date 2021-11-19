describe Theoj::PublishedPaper do

  describe "initialization" do
    it "should error if invalid DOI" do
      expect(Faraday).to receive(:get).with("https://doi.org/wrong-doi").and_return(double(status: 404))

      expect{ Theoj::PublishedPaper.new("wrong-doi")}.to raise_error("The DOI is invalid, url does not resolve https://doi.org/wrong-doi")
    end

    it "should error if paper's metadata can't be found" do
      doi_response = double(status: 302, headers: {location: "paper-url"})
      expect(Faraday).to receive(:get).with("https://doi.org/paper-doi").and_return(doi_response)
      expect(Faraday).to receive(:get).with("paper-url.json").and_return(double(status: 404))


      expect{ Theoj::PublishedPaper.new("paper-doi")}.to raise_error("Could not find the paper data at paper-url.json")
    end

    it "should initialize metadata" do
      doi_response = double(status: 302, headers: {location: "paper-url"})
      expect(Faraday).to receive(:get).with("https://doi.org/paper-doi").and_return(doi_response)
      paper_response = double(status: 200, body: { title: "Test paper", doi: "paper-doi", state: "accepted"}.to_json)
      expect(Faraday).to receive(:get).with("paper-url.json").and_return(paper_response)

      published_paper = Theoj::PublishedPaper.new("paper-doi")
      expect(published_paper.metadata[:title]).to eq("Test paper")
      expect(published_paper.metadata[:doi]).to eq("paper-doi")
      expect(published_paper.metadata[:state]).to eq("accepted")
    end
  end

  describe "metadata" do
    let(:metadata_methods) {
      [:title, :state, :submitted_at, :doi, :published_at,
       :volume, :issue, :year, :page, :authors, :editor,
       :editor_name, :editor_url, :editor_orcid, :reviewers,
       :languages, :tags, :software_repository, :paper_review,
       :pdf_url, :software_archive]
     }

    before do
      doi_response = double(status: 302, headers: {location: "paper-url"})
      expect(Faraday).to receive(:get).with("https://doi.org/paper-doi").and_return(doi_response)

      @metadata = { title: "Test paper", doi: "paper-doi", state: "accepted"}

      paper_response = double(status: 200, body: @metadata.to_json)
      expect(Faraday).to receive(:get).with("paper-url.json").and_return(paper_response)

      @published_paper = Theoj::PublishedPaper.new("paper-doi")
    end

    it "should have reader methods" do
      metadata_methods.each do |metadata_method|
        expect(@published_paper.respond_to?(metadata_method)).to be true
      end

      expect(@published_paper.title).to eq("Test paper")
      expect(@published_paper.doi).to eq("paper-doi")
      expect(@published_paper.state).to eq("accepted")
    end

    it "should be editable" do
      expect(@published_paper.title).to eq("Test paper")
      @published_paper.title = "New title"
      expect(@published_paper.title).to eq("New title")
      expect(@published_paper.metadata[:title]).to eq("New title")
    end

    it "should be available in json format" do
      expect(@published_paper.json_metadata).to eq(@metadata.to_json)
    end

    it "should be available in yaml format" do
      expect(@published_paper.yaml_metadata).to eq(@metadata.transform_keys(&:to_s).to_yaml)
    end
  end
end
