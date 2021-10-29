require "faraday"
require "yaml"
require "json"

module Theoj
  class PublishedPaper
    include Theoj::Git

    attr_accessor :metadata

    def initialize(doi)
      doi_url = "https://doi.org/#{doi}"
      doi_response = Faraday.get(doi_url)
      if doi_response.status == 302
        paper_url = doi_response.headers[:location]
      else
        raise "Error: the DOI is invalid, url does not resolve #{doi_url}"
      end

      paper_data = Faraday.get(paper_url + ".json")
      if paper_data.status == 200
        @metadata = JSON.parse(paper_data.body, symbolize_names: true)
      else
        raise "Error: Could not find the paper data at #{paper_url + ".json"}"
      end
    end

    [:title, :state, :submitted_at, :doi, :published_at,
     :volume, :issue, :year, :page, :authors, :editor,
     :editor_name, :editor_url, :editor_orcid, :reviewers,
     :languages, :tags, :software_repository, :paper_review,
     :pdf_url, :software_archive].each do |method_name|
      define_method(method_name) { metadata[method_name] }
      define_method("#{method_name}=") {|value| @metadata[method_name] = value }
    end

    def yaml_metadata
      metadata.to_yaml
    end

    def json_metadata
      metadata.to_json
    end

  end
end
