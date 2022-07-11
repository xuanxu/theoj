describe Theoj::Author do

  describe "initialization" do
    it "should parse name string" do
      name = "Ellen Louise Ripley"
      author = Theoj::Author.new(name, "0000-0001-2345-6789", nil, {})

      expect(author.name).to eq("Ellen Ripley")
    end

    it "should remove footnotes from the name string" do
      name = "Arfon Smith^[Corresponding author: arfon@arfon.arf]"
      author = Theoj::Author.new(name, "0000-0001-2345-6789", nil, {})

      expect(author.name).to eq("Arfon Smith")
    end

    it "should parse name hash" do
      name = { "given" => "James", "surname" => "Bond" }
      author = Theoj::Author.new(name, "0000-0001-2345-6789", nil, {})

      expect(author.name).to eq("James Bond")

      name = { "given" => "Ludwig", "dropping-particle" => "van", "surname" => "Beethoven" }
      author = Theoj::Author.new(name, "0000-0001-2345-6789", nil, {})

      expect(author.name).to eq("Ludwig Beethoven")
      expect(author.given_name).to eq("Ludwig")
      expect(author.middle_name).to eq("van")
      expect(author.last_name).to eq("Beethoven")
      expect(author.initials).to eq("L. v.")
    end

    it "should remove footnotes from the name hash" do
      name = "Arfon Smith^[Corresponding author: arfon@arfon.arf]"
      author = Theoj::Author.new(name, "0000-0001-2345-6789", nil, {})

      expect(author.name).to eq("Arfon Smith")
    end

    it "should build the affiliation string" do
      affiliations = {1 => "The Open Journals", 2 => "Nostromo", 3 => "Other"}
      author = Theoj::Author.new("E. Ripley", "0000-0001-2345-6789", 2, affiliations)

      expect(author.affiliation).to eq("Nostromo")
    end

    it "should accept multiple affiliations" do
      affiliations = {1 => "The Open Journals", 2 => "Nostromo", 3 => "Other"}
      author = Theoj::Author.new("E. Ripley", "0000-0001-2345-6789", "1,2", affiliations)

      expect(author.affiliation).to eq("The Open Journals, Nostromo")
    end

    it "should error if invalid affiliation" do
      expect {
        Theoj::Author.new("E. Ripley", "0000-0001-2345-6789", 1, {})
      }.to raise_error "Problem with affiliations for E. Ripley, perhaps the affiliations index need quoting?"
    end

    it "should validate the ORCID" do
      affiliations = {1 => "The Open Journals", 2 => "Nostromo", 3 => "Other"}

      author = Theoj::Author.new("E. Ripley", " 0000-0001-2345-6789  ", "1,2", affiliations)
      expect(author.orcid).to eq("0000-0001-2345-6789")

      author = Theoj::Author.new("E. Ripley", "  ", "1,2", affiliations)
      expect(author.orcid).to be_nil
    end

    it "should error if ORCID is invalid" do
      expect {
        Theoj::Author.new("E. Ripley", "0000-0000-0000-0008", nil, {})
      }.to raise_error "Problem with ORCID (0000-0000-0000-0008) for E. Ripley. Invalid ORCID"
    end
  end

  describe "parsed name" do
    before do
      name = "Ellen Louise Ripley"
      @author = Theoj::Author.new(name, "0000-0001-2345-6789", nil, {})
    end

    it "should assign give_name" do
      expect(@author.given_name).to eq("Ellen")
    end

    it "should assign middle_name" do
      expect(@author.middle_name).to eq("Louise")
    end

    it "should assign last_name" do
      expect(@author.last_name).to eq("Ripley")
    end

    it "should be used to create author's initials" do
      expect(@author.initials).to eq("E. L.")
    end
  end

  describe "#to_h" do
    it "should return a hash with all the author's info" do
      name = "Ellen Louise Ripley"
      affiliations = {1 => "The Open Journals", 2 => "Nostromo", 3 => "Other"}
      author = Theoj::Author.new(name, "0000-0001-2345-6789", "1,2", affiliations)

      expected_author_info = {
        given_name: "Ellen",
        middle_name: "Louise",
        last_name: "Ripley",
        orcid: "0000-0001-2345-6789",
        affiliation: "The Open Journals, Nostromo"
      }

      expect(author.to_h).to eq(expected_author_info)
    end
  end
end
