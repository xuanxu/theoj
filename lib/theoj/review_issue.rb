module Theoj
  class ReviewIssue
    attr_accessor :issue_id
    attr_accessor :repository
    attr_accessor :paper

    def initialize(issue_id, repository)
      @issue_id = issue_id
      @repository = repository
    end

    def issue_body
    end

  end
end
