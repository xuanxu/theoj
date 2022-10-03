require "json"
require "date"
require "base64"
require "faraday"
require "commonmarker"

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
        id: metadata_info[:review_issue_id],
        metadata: Base64.encode64(metadata_payload),
        doi: metadata_info[:doi],
        archive_doi: metadata_info[:archive_doi],
        citation_string: citation_string,
        title: metadata_info[:title]
      }
    end

    # Create a metadata json payload
    def metadata_payload
      {
        paper: {
          title: metadata_info[:title],
          tags: metadata_info[:tags],
          languages: metadata_info[:languages],
          authors: metadata_info[:authors],
          doi: metadata_info[:doi],
          archive_doi: metadata_info[:archive_doi],
          repository_address: metadata_info[:software_repository_url],
          editor: metadata_info[:review_editor],
          reviewers: metadata_info[:reviewers].collect(&:strip),
          volume: metadata_info[:volume],
          issue: metadata_info[:issue],
          year: metadata_info[:year],
          page: metadata_info[:page]
        }
      }.to_json
    end

    # Create metadata used to generate PDF/JATS outputs
    def article_metadata
      {
        title: metadata_info[:title],
        tags: metadata_info[:tags],
        authors: metadata_info[:authors],
        doi: metadata_info[:doi],
        software_repository_url: metadata_info[:software_repository_url],
        reviewers: metadata_info[:reviewers].collect{|r| user_login(r)},
        volume: metadata_info[:volume],
        issue: metadata_info[:issue],
        year: metadata_info[:year],
        page: metadata_info[:page],
        journal_alias: metadata_info[:journal_alias],
        software_review_url: metadata_info[:software_review_url],
        archive_doi: metadata_info[:archive_doi],
        citation_string: metadata_info[:citation_string],
        editor: metadata_info[:editor],
        submitted_at: metadata_info[:submitted_at],
        published_at: metadata_info[:published_at]
      }
    end

    def metadata_info
      @metadata_info ||= all_metadata
    end

    def deposit!(secret)
      parameters = deposit_payload.merge(secret: secret)
      Faraday.post(journal.data[:deposit_url], parameters.to_json, {"Content-Type" => "application/json"})
    end

    def citation_string
      metadata_info[:citation_string]
    end

    def paper_id
      journal.paper_id_from_issue(review_issue.issue_id)
    end

    def paper_doi
      journal.paper_doi_for_id(paper_id)
    end

    def all_metadata
      metadata = {
        title: plaintext(paper.title),
        tags: paper.tags,
        languages: paper.languages,
        authors: paper.authors.collect { |a| a.to_h },
        doi: paper_doi,
        software_repository_url: review_issue.target_repository,
        review_issue_id: review_issue.issue_id,
        review_editor: review_issue.editor,
        reviewers: review_issue.reviewers,
        volume: journal.current_volume,
        issue: journal.current_issue,
        year: journal.current_year,
        page: review_issue.issue_id,
        journal_alias: journal.alias,
        journal_name: journal.name,
        software_review_url: journal.reviews_repository_url(review_issue.issue_id),
        archive_doi: review_issue.archive,
        citation_author: paper.citation_author
      }

      metadata.merge!(editor_info, dates_info)
      metadata[:citation_string] = build_citation_string(metadata)
      metadata
    end

    def editor_info
      editor_info = { editor: {
                        github_user: user_login(review_issue.editor),
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
          dates_info[:submitted_at] = format_date(info[:submitted]) if info[:submitted]
          dates_info[:published_at] = format_date(info[:accepted]) if info[:accepted]
        end

        if dates_info[:published_at]
          yvi = journal.year_volume_issue_for_date(Date.parse(dates_info[:published_at]))
          dates_info[:year] = yvi[0]
          dates_info[:volume] = yvi[1]
          dates_info[:issue] = yvi[2]
        end
      end

      dates_info
    end

    def track
      track_info = { name: nil, short_name: nil, code: nil, label: nil, parameterized: nil}

      if review_issue.issue_id
        track_lookup = Faraday.get(journal.url + "/papers/" + review_issue.issue_id.to_s + "/lookup_track" )
        if track_lookup.status == 200
          track_info = JSON.parse(track_lookup.body, symbolize_names: true)
        end
      end

      track_info
    end

    private

    def build_citation_string(metadata)
      "#{metadata[:citation_author]}, (#{metadata[:year]}). #{metadata[:title]}. #{metadata[:journal_name]}, #{metadata[:volume]}(#{metadata[:issue]}), #{metadata[:review_issue_id]}, https://doi.org/#{metadata[:doi]}"
    end

    def plaintext(t)
      CommonMarker.render_doc(t, :DEFAULT).to_plaintext.strip.gsub(" ", " ")
    end

    def format_date(date_string)
      Date.parse(date_string.to_s).strftime("%Y-%m-%d")
    rescue Date::Error
      nil
    end
  end
end