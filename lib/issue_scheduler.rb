# frozen_string_literal: true

require_relative 'issue_scheduler/config'
require_relative 'issue_scheduler/issue_template'
require_relative 'issue_scheduler/version'

# A module to encapsulate the Issue Scheduler functionality
# @api puiblic
module IssueScheduler
  # Return the directory where the Issue Scheduler code is located
  #
  # @example
  #   IssueScheduler.lib_dir #=> '/path/to/issue_scheduler'
  #
  # @return [String] the directory where the Issue Scheduler code is located
  #
  # @api public
  def self.lib_dir
    File.join(__dir__, 'issue_scheduler')
  end

  # Parses the given YAML string
  #
  # @example
  #   yaml = <<~YAML
  #     username: user
  #     password: pass
  #   YAML
  #   IssueScheduler.parse_yaml(yaml) #=> { username: 'user', password: 'pass' }
  #
  # @param yaml_string [String] the YAML object to parse
  # @raise [RuntimeError] if the YAML is not valid or is not an object
  # @return [Hash] the parsed YAML object as a Hash
  #
  # @api public
  #
  def self.parse_yaml(yaml_string)
    yaml_options = { permitted_classes: [Symbol, Date], aliases: true, symbolize_names: true }
    YAML.safe_load(yaml_string, **yaml_options).tap do |yaml|
      raise 'YAML is not an object' unless yaml.is_a?(Hash)
    end
  rescue Psych::SyntaxError => e
    raise "YAML is not valid: #{e.message}"
  end

  # Reads the contents of the given YAML file
  #
  # @example
  #   File.write('data.yaml', <<~YAML)
  #     username: user
  #     password: pass
  #   YAML
  #   IssueScheduler.read_yaml('data.yaml') #=> { username: 'user', password: 'pass' }
  #
  # @param file_name [String] the file name to read
  #
  # @raise [RuntimeError] if the file cannot be read or the parsed YAML is not valid or
  #   not an object
  #
  # @return [Hash] the parsed YAML object as a Hash
  #
  # @api public
  #
  def self.load_yaml(file_name)
    yaml_string = File.read(file_name)
    parse_yaml(yaml_string)
  rescue Errno::ENOENT => e
    raise "Error reading YAML file: #{e.message}"
  end
end
