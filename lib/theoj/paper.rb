require 'find'
require 'yaml'

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

    def find_paper(path)
      if path.to_s.strip.empty?
        setup_local_repo
        @paper_path = Theoj::Paper.find_paper_path(local_path)
      else
        @paper_path = path
      end
    end

    def authors
      []
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

    def cleanup
      FileUtils.rm_rf(local_path) if Dir.exist?(local_path)
    end

    private
      def setup_local_repo
        msg_no_repo = "Downloading of the repository failed. Please make sure the URL is correct."
        msg_no_branch = "Couldn't check the bibtex because branch name is incorrect: #{branch.to_s}"

        error = clone_repo(repository, local_path) ? nil : msg_no_repo
        (error = change_branch(branch, local_path) ? nil : msg_no_branch) unless error

        failure(error) if error
        error.nil?
      end

      def local_path
        @local_path ||= "tmp/#{SecureRandom.hex}"
      end

      def load_metadata
        @paper_metadata ||= if paper_path.include?('.tex')
          YAML.load_file(paper_path.gsub('.tex', '.yml'))
        else
          YAML.load_file(paper_path)
        end
      end

      def failure(msg)
        cleanup
        raise(msg)
      end
  end
end
