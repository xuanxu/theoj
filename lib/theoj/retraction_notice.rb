require "faraday"
require "yaml"
require "json"

module Theoj
  class RetractionNotice

    attr_accessor :retracted_paper
    attr_accessor :journal

    def initialize(doi, journal_alias)
      journal_data = Theoj::JOURNALS_DATA[journal_alias.to_sym]
      if journal_data.nil?
        raise Theoj::Error, "Can't find journal #{journal_alias}"
      end
      @journal = Theoj::Journal.new(journal_data)
      @retracted_paper = Theoj::PublishedPaper.new(doi)
    end

    def metadata
      {
        title: "Retraction notice for: " + retracted_paper.title,
        tags: retracted_paper.tags,
        authors: [{ given_name: journal.alias.upcase,
                    last_name: "Editorial Board",
                    affiliation: journal.name}],
        doi: retracted_paper.doi + "R",
        software_repository_url: retracted_paper.software_repository,
        reviewers: [],
        volume: journal.current_volume,
        issue: journal.current_issue,
        year: journal.current_year,
        page: "#{retracted_paper.page}R",
        journal_alias: journal.alias,
        software_review_url: retracted_paper.paper_review,
        archive_doi: retracted_paper.software_archive.to_s.gsub("https://doi.org/", ""),
        editor: { github_user: "openjournals", name: "Editorial Board", url: journal.data[:url] },
        submitted_at: Time.now.strftime("%Y-%m-%d"),
        published_at: Time.now.strftime("%Y-%m-%d")
      }
    end

    # Create the payload to use to post for depositing with Open Journals
    def deposit_payload
      metadata_payload = {
        paper: {
          title: metadata[:title],
          tags: metadata[:tags],
          languages: [],
          authors: metadata[:authors],
          doi: metadata[:doi],
          archive_doi: metadata[:archive_doi],
          repository_address: metadata[:software_repository_url],
          editor: metadata[:editor][:github_user],
          reviewers: metadata[:reviewers],
          volume: metadata[:volume],
          issue: metadata[:issue],
          year: metadata[:year],
          page: metadata[:page]
        }
      }.to_json

      {
        doi: metadata[:doi],
        metadata: Base64.encode64(metadata_payload),
        citation_string: citation_string
      }
    end

    def citation_string
      "Editorial Board, (#{metadata[:year]}). #{metadata[:title]}. #{journal.name}, #{metadata[:volume]}(#{metadata[:issue]}), #{metadata[:page]}, https://doi.org/#{metadata[:doi]}"
    end

    def deposit!(secret)
      parameters = deposit_payload.merge(secret: secret)
      Faraday.post(journal.data[:retract_url], parameters.to_json, {"Content-Type" => "application/json"})
    end
  end
end
