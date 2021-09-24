module CommonActions
  def disable_github_calls
    allow_any_instance_of(Octokit::Client).to receive(:issue).and_return(true)
    allow_any_instance_of(Octokit::Client).to receive(:labels_for_issue).and_return([])
    allow_any_instance_of(Octokit::Client).to receive(:collaborator?).and_return(true)
    allow_any_instance_of(Octokit::Client).to receive(:check_assignee).and_return(true)
    allow_any_instance_of(Octokit::Client).to receive(:repository_invitations).and_return(true)

    allow(Octokit::Client).to receive(:new).and_return(Octokit::Client.new())
  end

  def fixture(file_name)
    File.dirname(__FILE__) + '/fixtures/' + file_name
  end
end
