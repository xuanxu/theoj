require "find"
require "yaml"
require "rugged"
require "linguist"

module Theoj
  class Paper
    include Theoj::Git

    attr_accessor :review_issue
    attr_accessor :repository
    attr_accessor :paper_path
    attr_accessor :branch
    attr_accessor :paper_metadata

    def initialize(repository_url, branch, path = nil)
      @repository = repository_url
      @branch = branch
      find_paper path
      load_metadata
    end

    def authors
      @authors ||= parse_authors
    end

    def citation_author
      surname = authors.first.last_name
      initials = authors.first.initials

      if authors.size > 1
        return "#{surname} et al."
      else
        return "#{surname}, #{initials}"
      end
    end

    def title
      @paper_metadata["title"]
    end

    def tags
      @paper_metadata["tags"]
    end

    def date
      @paper_metadata["date"]
    end

    def languages
      @languages ||= detect_languages
    end

    def bibliography_path
      @paper_metadata["bibliography"]
    end

    def local_path
      @local_path ||= "tmp/#{SecureRandom.hex}"
    end

    def cleanup
      FileUtils.rm_rf(local_path) if Dir.exist?(local_path)
    end

    def self.find_paper_path(search_path)
      paper_path = nil

      if Dir.exist? search_path
        Find.find(search_path).each do |path|
          if path =~ /paper\.tex$|paper\.md$/
            paper_path = path
            break
          end
        end
      end

      paper_path
    end

    def self.from_repo(repository_url, branch = "")
      Paper.new(repository_url, branch, nil)
    end

    private

      def find_paper(path)
        if path.to_s.strip.empty?
          setup_local_repo
          @paper_path = Theoj::Paper.find_paper_path(local_path)
        else
          @paper_path = path
        end
      end

      def setup_local_repo
        msg_no_repo = "Downloading of the repository failed. Please make sure the URL is correct."
        msg_no_branch = "Couldn't check the bibtex because branch name is incorrect: #{branch.to_s}"

        error = clone_repo(repository, local_path) ? nil : msg_no_repo
        (error = change_branch(branch, local_path) ? nil : msg_no_branch) unless error

        failure(error) if error
        error.nil?
      end

      def load_metadata
        @paper_metadata ||= if paper_path.nil?
          {}
        elsif paper_path.include?('.tex')
          YAML.load_file(paper_path.gsub('.tex', '.yml'))
        else
          YAML.load_file(paper_path)
        end
      end

      def parse_authors
        parsed_authors = []
        authors_metadata = @paper_metadata['authors']
        affiliations_metadata = parse_affiliations(@paper_metadata['affiliations'])

        # Loop through the authors block and build up the affiliation
        authors_metadata.each do |author|
          author['name'] = author.dup if author['name'].nil?
          affiliation_index = author['affiliation']
          failure "Author (#{author['name']}) is missing affiliation" if affiliation_index.nil?
          begin
            parsed_author = Author.new(author['name'], author['orcid'], affiliation_index, affiliations_metadata)
          rescue Exception => e
            failure(e.message)
          end
          parsed_authors << parsed_author
        end

        parsed_authors
      end

      def parse_affiliations(affiliations_yaml)
        affiliations_metadata = {}

        affiliations_yaml.each do |affiliation|
          affiliations_metadata[affiliation['index']] = affiliation['name']
        end

        affiliations_metadata
      end

      def detect_languages
        repo = Rugged::Repository.discover(paper_path)
        project = Linguist::Repository.new(repo, repo.head.target_id)

        # Take top five languages from Linguist
        project.languages.keys.take(5)
      end

      def failure(msg)
        cleanup
        raise Theoj::Error, msg
      end
  end
end
