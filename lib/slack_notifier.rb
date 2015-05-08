require 'net/https'

unless defined?(BuilderPlugin)
  # Define a dummy Plugin class if not already available
  # This allows for compatibility with very old cc.rb 1.4 deployments
  class BuilderPlugin
  end
end

class SlackNotifier < BuilderPlugin
  attr_accessor :url, :token, :channel
  attr_accessor :only_failed_builds, :only_fixed_and_broken_builds, :only_first_failure

  def initialize(project=nil)
    @url = nil
    @token = nil
    @channel = nil
    @only_failed_builds = false
    @only_fixed_and_broken_builds = false
    @only_first_failure = false
  end

  alias_method :password=, :token=

  def enabled?
    url && token && channel
  end

  def build_finished(build)
    return if only_fixed_and_broken_builds
    if build.successful?
      notify_of_build_outcome(build, "PASSED") unless only_failed_builds
    else
      notify_of_build_outcome(build, "FAILED!") unless only_first_failure
    end
  end

  def build_broken(broken_build, previous_build)
    notify_of_build_outcome(broken_build, "BROKE!") if only_first_failure || only_fixed_and_broken_builds
  end

  def build_fixed(fixed_build, previous_build)
    notify_of_build_outcome(fixed_build, "WAS FIXED") if only_fixed_and_broken_builds
  end

  def get_changeset_committers(build)
    log_parser = eval("#{build.project.source_control.class}::LogParser").new
    revisions = log_parser.parse( build.changeset.split("\n") ) rescue []
    committers = revisions.collect { |rev| rev.committed_by }.uniq
    committers
  end

  def notify_of_build_outcome(build, message)
    return unless self.enabled?

    CruiseControl::Log.debug("Slack notifier: sending notices")

    committers = self.get_changeset_committers(build) || []

    urls = []
    urls << build.url if Configuration.dashboard_url

    message_text = %(*#{build.project.name} build #{build.label} #{message}*
#{committers.join(", ") if committers.any?}
#{urls.join(" | ")})

    post_to_slack!(message_text)
  end

  def slack_endpoint
    "#{url}/services/hooks/slackbot?token=#{token}&channel=#{channel}"
  end

  def post_to_slack!(message)
    uri = URI.parse(slack_endpoint)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    request = Net::HTTP::Post.new(uri.request_uri)
    request.body = message
    http.request(request)
  rescue => e
    raise "Slack Communication Error: #{e.message}"
  end

end

Project.plugin :slack_notifier if ENV["ENV"] != "test"
