require 'find'

module Theoj
  class Paper
    include Theoj::Git

    attr_accessor :review_issue
    attr_accessor :repository
    attr_accessor :paper_path

    def initialize(repository, branch, path = nil)
      @repository = repository
      @branch = branch
      find_paper path
    end

    def find_paper(path)
      if path.to_s.strip.empty?
        setup_local_repo
        @paper_path = Theoj::Paper.find_paper_path(local_path)
        cleanup
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

    def self.from_repo(repository, branch = "main")
      Paper.new(repository, branch, nil)
    end

    private
      def setup_local_repo
        msg_no_repo = "Downloading of the repository failed. Please make sure the URL is correct."
        msg_no_branch = "Couldn't check the bibtex because branch name is incorrect: #{paper_branch.to_s}"

        error = clone_repo(target_repository, local_path) ? nil : msg_no_repo
        (error = change_branch(paper_branch, local_path) ? nil : msg_no_branch) unless error

        failure(error) if error
        error.nil?
      end

      def local_path
        @local_path ||= "tmp/#{SecureRandom.hex}"
      end

      def cleanup
        FileUtils.rm_rf(local_path) if Dir.exist?(local_path)
      end

      def failure(msg)
        cleanup
        raise(msg)
      end
  end
end
