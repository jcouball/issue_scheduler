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
class IssueWorker
  include Sidekiq::Worker

  def perform(*args)
    puts "**** IssueWorker#perform called with #{args.inspect}"
  end
end
