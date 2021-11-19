describe Theoj::Journal do

  describe "initialization" do
    it "should use default data" do
      default_journal = Theoj::Journal.new

      expect(default_journal.doi_prefix).to eq("10.21105")
      expect(default_journal.url).to eq("https://joss.theoj.org")
      expect(default_journal.name).to eq("Journal of Open Source Software")
      expect(default_journal.alias).to eq("joss")
      expect(default_journal.launch_date).to eq("2016-05-05")
      expect(default_journal.data[:deposit_url]).to eq("https://joss.theoj.org/papers/api_deposit")
    end

    it "should use custom data" do
      default_journal = Theoj::Journal.new(doi_prefix: "10.33333", name: "Test Journal", launch_date: "2021-09-23")

      expect(default_journal.doi_prefix).to eq("10.33333")
      expect(default_journal.url).to eq("https://joss.theoj.org")
      expect(default_journal.name).to eq("Test Journal")
      expect(default_journal.alias).to eq("joss")
      expect(default_journal.launch_date).to eq("2021-09-23")
    end
  end

  describe "current journal dates" do
    before do
      @journal = Theoj::Journal.new(launch_date: "2019-11-17")
      @now = Time.new
      @launch = Time.parse("2019-11-17")
    end

    it "current year should be now.year" do
      expect(@journal.current_year).to eq(@now.year)
    end

    it "current volume should be based on launch date" do
      expect(@journal.current_volume).to eq(@now.year - @launch.year + 1)
    end

    it "current issue should be based on launch date" do
      now = Time.new
      launch = Time.parse("2019-11-17")
      expect(@journal.current_issue).to eq((@now.year - @launch.year)*12 + @now.month - @launch.month + 1)
    end

    it "should be configurable" do
      journal = Theoj::Journal.new(launch_date: "2019-11-17", current_year: 10, current_volume: 33, current_issue: 3042)
      expect(journal.current_year).to eq(10)
      expect(journal.current_volume).to eq(33)
      expect(journal.current_issue).to eq(3042)
    end
  end

  describe "#paper_id_from_issue" do
    it "should use journal alias and the issue's id" do
      journal = Theoj::Journal.new(alias: "great_journal")
      expect(journal.paper_id_from_issue(33)).to eq("great_journal.00033")
    end
  end

  describe "#paper_doi_for_id" do
    it "should use journal's DOI prefix and the paper's id" do
      journal = Theoj::Journal.new(doi_prefix: "10.12345")
      expect(journal.paper_doi_for_id("sciencejournal.00042")).to eq("10.12345/sciencejournal.00042")
    end
  end

  describe "#reviews_repository_url" do
    it "should return complete url for the reviews repo" do
      journal = Theoj::Journal.new
      expect(journal.reviews_repository_url).to eq("https://github.com/openjournals/joss-reviews")
    end

    it "should return complete url for an issue from the reviews repo" do
      journal = Theoj::Journal.new(reviews_repository: "test-org/paper-reviews")
      expect(journal.reviews_repository_url(33)).to eq("https://github.com/test-org/paper-reviews/issues/33")
    end
  end
end
