# frozen_string_literal: true

require 'pp'
require 'sidekiq'
require 'sidekiq-cron'

Sidekiq.configure_client do |config|
  config.redis = { db: 1 }
  config.on(:startup) do
    job_properties = {
      'name' => 'weekly_status_update',
      'description' => 'Create a JIRA task to update the weekly status',
      'cron' => '1 * * * *',
      'class' => 'IssueWorker',
      'args' => ['weekly_status_update'],
      'date_as_argument' => true
    }

    job = Sidekiq::Cron::Job.new(job_properties)
    raise "Error creating job: #{job.errors.pretty_inspect}" unless job.valid?

    job.save
  end
end

Sidekiq.configure_server do |config|
  config.redis = { db: 1 }
end

# My worker class that creates issues
# @api private
class IssueWorker
  include Sidekiq::Worker

  # Create an issue with the given template name
  # @param template_name [String] the name of the template to use
  # @param time [Time] the time to use for the issue
  # @return [void]
  # @api private
  def perform(template_name, time)
    puts "**** IssueWorker#perform called with #{template_name.pretty_inspect}, #{time.pretty_inspect}"
  end
end
