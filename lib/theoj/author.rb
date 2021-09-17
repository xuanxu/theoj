module Theoj
  class Author
    attr_accessor :name
    attr_accessor :orcid
    attr_accessor :affiliation

    def initialize(name, orcid, affiliation)
      @name = name
      @orcid = orcid
      @affiliation = affiliation
    end

    def validate_orcid
    end

  end
end
