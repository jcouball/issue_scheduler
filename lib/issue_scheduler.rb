# frozen_string_literal: true

require_relative 'issue_scheduler/config'
require_relative 'issue_scheduler/issue_template'
require_relative 'issue_scheduler/version'

# A module to encapsulate the Issue Scheduler functionality
# @api puiblic
module IssueScheduler
  def self.lib_dir
    File.join(__dir__, 'issue_scheduler')
  end
end
