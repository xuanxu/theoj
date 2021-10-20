require "json"
require "base64"

module Theoj
  class Submission
    attr_accessor :journal
    attr_accessor :review_issue
    attr_accessor :paper

    def initialize(journal, review_issue, paper=nil)
      @journal = journal
      @review_issue = review_issue
      @paper = paper || @review_issue.paper
    end

    # Create the payload to use to post for depositing with Open Journals
    def deposit_payload
      {
        id: review_issue.issue_id,
        metadata: Base64.encode64(metadata_payload),
        doi: paper_doi,
        archive_doi: review_issue.archive,
        citation_string: citation_string,
        title: paper.title
      }
    end

    # Create a metadata json payload
    def metadata_payload
      metadata = {
        paper: {
          title: paper.title,
          tags: paper.tags,
          languages: paper.languages,
          authors: paper.authors.collect { |a| a.to_h },
          doi: paper_doi,
          archive_doi: review_issue.archive,
          repository_address: review_issue.target_repository,
          editor: review_issue.editor,
          reviewers: review_issue.reviewers.collect(&:strip),
          volume: journal.current_volume,
          issue: journal.current_issue,
          year: journal.current_year,
          page: review_issue.issue_id,
        }
      }

      metadata.to_json
    end

    def citation_string
      paper_year = Time.now.strftime('%Y')
      "#{paper.citation_author}, (#{paper_year}). #{paper.title}. #{journal.name}, #{journal.current_volume}(#{journal.current_issue}), #{review_issue.issue_id}, https://doi.org/#{paper_doi}"
    end

    def paper_id
      journal.paper_id_from_issue(review_issue.issue_id)
    end

    def paper_doi
      journal.paper_doi_for_id(paper_id)
    end
  end
end