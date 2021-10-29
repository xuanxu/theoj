require_relative "theoj/version"
require_relative "theoj/git"
require_relative "theoj/github"
require_relative "theoj/orcid"
require_relative "theoj/published_paper"
require_relative "theoj/submission"
require_relative "theoj/journal"
require_relative "theoj/review_issue"
require_relative "theoj/paper"
require_relative "theoj/author"

module Theoj
  class Error < StandardError; end
end
