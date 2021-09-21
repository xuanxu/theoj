require "octokit"

# This module includes all the methods involving calls to the GitHub API
# It reuses a memoized Octokit::Client instance
module Theoj
  module GitHub

    # Authenticated Octokit
    def github_client
      @github_client ||= Octokit::Client.new(access_token: github_access_token, auto_paginate: true)
    end

    # GitHub access token
    def github_access_token
      @github_access_token ||= ENV["GH_ACCESS_TOKEN"]
    end

    # GitHub API headers
    def github_headers
      @github_headers ||= { "Authorization" => "token #{github_access_token}",
                            "Content-Type" => "application/json",
                            "Accept" => "application/vnd.github.v3+json" }
    end

    # Return an Octokit GitHub Issue
    def issue(repo, issue_id)
      @issue ||= github_client.issue(repo, issue_id)
    end

    # List labels of a GitHub issue
    def issue_labels(repo, issue_id)
      github_client.labels_for_issue(repo, issue_id).map { |l| l[:name] }
    end

    # Uses the GitHub API to determine if a user is already a collaborator of the repo
    def is_collaborator?(repo, username)
      username = user_login(username)
      github_client.collaborator?(repo, username)
    end

    # Uses the GitHub API to determine if a user is already a collaborator of the repo
    def can_be_assignee?(repo, username)
      username = user_login(username)
      github_client.check_assignee(repo, username)
    end

    # Uses the GitHub API to determine if a user has a pending invitation
    def is_invited?(repo, username)
      username = user_login(username)
      github_client.repository_invitations(repo).any? { |i| i.invitee.login.downcase == username }
    end

    # Returns the user login (removes the @ from the username)
    def user_login(username)
      username.strip.sub(/^@/, "").downcase
    end

    # Returns true if the string is a valid GitHub isername (starts with @)
    def username?(username)
      username.match?(/\A@/)
    end
  end
end
