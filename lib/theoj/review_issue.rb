require "securerandom"

module Theoj
  class ReviewIssue
    include Theoj::GitHub

    attr_accessor :issue_id
    attr_accessor :repository
    attr_accessor :paper
    attr_accessor :local_path

    def initialize(repository, issue_id, access_token=nil)
      @issue_id = issue_id
      @repository = repository
      @github_access_token = access_token
    end

    def issue_body
      issue(repository, issue_id).body
    end

    def paper

    end

    def target_repository
      @target_repository ||= read_value_from_body("target-repository")
    end

    def paper_branch
      @paper_branch ||= read_value_from_body("branch")
    end

    private

      def read_from_body(start_mark, end_mark)
        text = ""
        issue_body.match(/#{start_mark}(.*)#{end_mark}/im) do |m|
          text = m[1]
        end
        text.strip
      end

      # Read value in issue's body between HTML comments
      def read_value_from_body(value_name)
        start_mark = "<!--#{value_name}-->"
        end_mark = "<!--end-#{value_name}-->"
        read_from_body(start_mark, end_mark)
      end

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
