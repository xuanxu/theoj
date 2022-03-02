require "open3"
require "fileutils"

module Theoj
  module Git
    def clone_repo(url, local_path)
      url = URI.extract(url.to_s).first
      return false if url.nil?

      FileUtils.mkdir_p(local_path)
      stdout, stderr, status = Open3.capture3 "git clone #{url} #{local_path}"
      status.success?
    end

    def change_branch(branch, local_path)
      return true if (branch.nil? || branch.strip.empty?)
      stdout, stderr, status = Open3.capture3 "git -C #{local_path} switch #{branch}"
      status.success?
    end
  end
end