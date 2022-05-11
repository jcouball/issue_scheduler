# frozen_string_literal: true

require 'pp'
require 'sidekiq'
require 'sidekiq-cron'
require 'issue_scheduler'
require 'jira-ruby'

issue_config = IssueScheduler::Config.new(IssueScheduler.load_yaml('config/config.yaml'))
issue_config.load_issue_templates

Sidekiq.configure_client do |config|
  config.redis = { db: 1 }
end

Sidekiq.configure_server do |config|
  config.redis = { db: 1 }

  config.on(:startup) do
    Sidekiq::Cron::Job.destroy_all!

    IssueScheduler::IssueTemplate.all.each do |issue_template|
      job_properties = {
        'name' => issue_template.name,
        'description' => issue_template.summary,
        'cron' => issue_template.cron,
        'class' => 'IssueWorker',
        'args' => issue_template.name,
        'date_as_argument' => true
      }

      job = Sidekiq::Cron::Job.new(job_properties)
      raise "Error creating job: #{job.errors.pretty_inspect}" unless job.valid?

      job.save
    end
  end
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
    puts "**** IssueWorker#perform called with #{template_name.pretty_inspect.chomp}, #{time.pretty_inspect.chomp}"

    template = load_issue_template(template_name)
    return unless template

    create_issue(template)

    puts '**** IssueWorker#perform finished'
  end

  private

  # Create a Jira issue based on the following template
  #
  # @param template [IssueScheduler::IssueTemplate] the template to base the issue from
  # @return [void]
  # @api private
  def create_issue(template)
    puts ">>>> Creating issue with template: #{template.name}"

    issue = jira_client.Issue.build

    fields = { 'project' => { 'key' => template.project }, 'summary' => template.summary }

    # fields['component'] = { 'key' => template.component } if template.component
    fields['issuetype'] = { 'name' => template.type } if template.type
    # fields['description'] = template.description if template.description
    # fields['duedate'] = template.due_date.strftime('%Y-%m-%d') if template.due_date

    issue.save({ 'fields' => fields })
    issue.fetch

    puts ">>>> Created issue #{issue.key}"
  end

  # Create and memoize a Jira Client
  #
  # @return [JIRA::Client] the Jira client to be used to create issues
  # @api private
  def jira_client
    @jira_client ||= JIRA::Client.new(issue_config.to_jira_options)
  end

  # Create and memoize a IssueScheduler::Config
  #
  # @return [IssueScheduler::Config] the config to be used to create issues
  # @api private
  def issue_config
    @issue_config ||= IssueScheduler::Config.new(IssueScheduler.load_yaml('config/config.yaml'))
  end

  # Load the IssueScheduler::IssueTemplate with the given name
  #
  # @return [IssueScheuler::IssueTemplate] the template with the given name
  # @api private
  def load_issue_template(template_name)
    issue_config.load_issue_templates
    IssueScheduler::IssueTemplate.find(template_name)
  end
end
