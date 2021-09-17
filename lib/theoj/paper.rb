module Theoj
  class Paper
    attr_accessor :review_issue
    attr_accessor :repository
    attr_accessor :paper_path

    def initialize(repository, branch = "main")
      @repository = repository
      @branch = branch

      find_paper_path
    end

    def find_paper_path
    end

    def authors
      []
    end

  end
end
