describe Theoj::Orcid do

  describe "initialization" do
    it "should strip orcid string" do
      orcid = Theoj::Orcid.new("  0000-0000-0000-0007 ")

      expect(orcid.orcid).to eq("0000-0000-0000-0007")
    end

    it "should have no error" do
      orcid = Theoj::Orcid.new("0000-0000-0000-0007")

      expect(orcid.error).to eq(nil)
    end
  end

  describe "#valid?" do
    it "should be false if string has the wrong structure" do
      orcid = Theoj::Orcid.new("0000-0000-0000-0007-0000")

      expect(orcid.valid?).to be_falsey
      expect(orcid.error).to eq("ORCID looks malformed")
    end

    it "should be false if string has the wrong length" do
      orcid = Theoj::Orcid.new("0000-0000-0000-007")

      expect(orcid.valid?).to be_falsey
      expect(orcid.error).to eq("ORCID looks to be the wrong length")
    end

    it "should be false if string has invalid characters" do
      orcid = Theoj::Orcid.new("0000-0000-0000-0W07")

      expect(orcid.valid?).to be_falsey
      expect(orcid.error).to eq("Invalid ORCID digit (W)")
    end

    it "should be false if wrong checksum" do
      orcid = Theoj::Orcid.new("0000-0000-0000-0007")

      expect(orcid.valid?).to be_falsey
      expect(orcid.error).to eq("Invalid ORCID")
    end

    it "should be true for valid ORCIDs" do
      orcid = Theoj::Orcid.new("0000-0001-7699-3983")

      expect(orcid.valid?).to be_truthy
      expect(orcid.error).to be_nil
    end


  end

  describe "#packed_orcid" do
    it "should not include hyphens" do
      orcid = Theoj::Orcid.new("0000-0000-0000-0007")

      expect(orcid.packed_orcid).to eq("0000000000000007")
    end
  end
end
