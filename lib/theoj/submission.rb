require "json"
require "base64"
require "faraday"

module Theoj
  class Submission
    include Theoj::GitHub

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

    # Create metadata used to generate PDF/JATS outputs
    def article_metadata
        metadata = {
          title: paper.title,
          tags: paper.tags,
          languages: paper.languages,
          authors: paper.authors.collect { |a| a.to_h },
          doi: paper_doi,
          software_repository_url: review_issue.target_repository,
          reviewers: review_issue.reviewers.collect(&:strip),
          volume: journal.current_volume,
          issue: journal.current_issue,
          year: journal.current_year,
          page: review_issue.issue_id,
          software_review_url: journal.reviews_repository_url(review_issue.issue_id),
          archive_doi: review_issue.archive,
          citation_string: citation_string
        }

        metadata.merge(editor_info, dates_info)
    end

    def editor_info
      editor_info = { editor: {
                        github_user: review_issue.editor,
                        name: nil,
                        url: nil,
                        orcid: nil
                        }
                    }

      if review_issue.editor
        editor_lookup = Faraday.get(journal.url + "/editors/lookup/" + user_login(review_issue.editor))
        if editor_lookup.status == 200
          info = JSON.parse(editor_lookup.body, symbolize_names: true)
          editor_info[:editor][:name] = info[:name]
          editor_info[:editor][:url] = info[:url]
          editor_info[:editor][:orcid] = info[:orcid]
        end
      end

      editor_info
    end

    def dates_info
      dates_info = { submitted_at: nil, published_at: nil }

      if review_issue.issue_id
        paper_lookup = Faraday.get(journal.url + "/papers/lookup/" + review_issue.issue_id.to_s)
        if paper_lookup.status == 200
          info = JSON.parse(paper_lookup.body, symbolize_names: true)
          dates_info[:submitted_at] = info[:submitted]
          dates_info[:published_at] = info[:accepted]
        end
      end

      dates_info
    end

    def deposit!(secret)
      parameters = deposit_payload.merge(secret: secret)
      Faraday.post(journal.data[:deposit_url], parameters.to_json, {"Content-Type" => "application/json"})
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