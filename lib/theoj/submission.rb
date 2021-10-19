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
      payload = {
        'paper' => {}
      }

      %w(title tags languages).each { |var| payload['paper'][var] = paper.send(var) }
      payload['paper']['authors'] = paper.authors.collect { |a| a.to_h }
      payload['paper']['doi'] = paper_doi
      payload['paper']['archive_doi'] = review_issue.archive
      payload['paper']['repository_address'] = review_issue.target_repository
      payload['paper']['editor'] = review_issue.editor
      payload['paper']['reviewers'] = review_issue.reviewers.collect(&:strip)
      payload['paper']['volume'] = journal.current_volume
      payload['paper']['issue'] = journal.current_issue
      payload['paper']['year'] = journal.current_year
      payload['paper']['page'] = review_issue.issue_id

      payload
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