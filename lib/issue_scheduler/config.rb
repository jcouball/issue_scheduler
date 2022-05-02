# frozen_string_literal: true

require 'yaml'

module IssueScheduler
  # Manage the configuration for the YCA EOL Dashboard program
  # @api public
  class Config
    # Create a new Config object from a given YAML config
    # @example
    #   config_yaml = <<~CONFIG
    #     { username: user, password: pass, site: https://jira.mydomain.com, auth_type: basic }
    #   CONFIG
    #   config = IssueScheduler::Config.new(config_yaml)
    #
    # @param config_yaml [String] the config in YAML format
    #
    def initialize(config_yaml)
      config_from_yaml = parse_config(config_yaml)
      assert_config_is_an_object(config_from_yaml)
      @config = DEFAULT_VALUES.merge(config_from_yaml)
      assert_no_unexpected_keys(config)
      assert_all_values_are_non_nil(config)
    end

    # The username to use when authenticating with Jira
    #
    # @example
    #   config_yaml = <<~CONFIG
    #     { username: user, password: pass, site: https://jira.mydomain.com, auth_type: basic }
    #   CONFIG
    #   config = IssueScheduler::Config.new(config_yaml)
    #   config.username #=> 'user'
    #
    # @return [String] the username
    #
    def username
      config[:username]
    end

    # The password to use when authenticating with Jira
    #
    # @example
    #   config_yaml = <<~CONFIG
    #     { username: user, password: pass, site: https://jira.mydomain.com, auth_type: basic }
    #   CONFIG
    #   config = IssueScheduler::Config.new(config_yaml)
    #   config.password #=> 'pass'
    #
    # @return [String] the password
    #
    def password
      config[:password]
    end

    # The URL of the Jira server
    #
    # @example
    #   config_yaml = <<~CONFIG
    #     { username: user, password: pass, site: https://jira.mydomain.com, auth_type: basic }
    #   CONFIG
    #   config = IssueScheduler::Config.new(config_yaml)
    #   config.site #=> 'https://jira.mydomain.com'
    #
    # @return [String] the Jira URL
    #
    def site
      config[:site]
    end

    # The context path to append to the Jira server URL
    #
    # @example
    #   config_yaml = <<~CONFIG
    #     { username: user, password: pass, site: https://jira.mydomain.com, context_path: /jira, auth_type: basic }
    #   CONFIG
    #   config = IssueScheduler::Config.new(config_yaml)
    #   config.context_path #=> '/jira'
    #
    # @return [String] the context path
    #
    def context_path
      config[:context_path]
    end

    # The authentication type to use when authenticating with Jira
    #
    # @example
    #   config_yaml = <<~CONFIG
    #     { username: user, password: pass, site: https://jira.mydomain.com, auth_type: basic }
    #   CONFIG
    #   config = IssueScheduler::Config.new(config_yaml)
    #   config.auth_type #=> 'basic'
    #
    # @return ['basic', 'oauth'] the authentication type
    #
    def auth_type
      config[:auth_type]
    end

    # The glob pattern to use to find issue files
    #
    # @example
    #   config_yaml = <<~CONFIG
    #     {
    #       username: user, password: pass, site: https://jira.mydomain.com, auth_type: basic,
    #       issue_files: 'config/**/*.yaml'
    #     }
    #   CONFIG
    #   config = IssueScheduler::Config.new(config_yaml)
    #   config.issue_files #=> 'config/**/*.yaml'
    #
    # @return [String] the glob pattern
    #
    # @see https://ruby-doc.org/core-3.1.2/Dir.html#method-c-glob Dir.glob
    #
    def issue_files
      config[:issue_files]
    end

    # The config in the form of a Hash
    #
    # @example
    #   config = IssueScheduler::Config.new(<<~YAML)
    #     username: jcouball
    #     password: my_password
    #     site: https://jira.example.com
    #     context_path: ''
    #     auth_type: basic
    #     issue_files: '~/scheduled_issues/**/*.yaml'
    #   YAML
    #   config.to_h #=> { 'username' => 'jcouball', 'password' => 'my_password', ... }
    #
    # @return [Hash] the config
    #
    def to_h
      config
    end

    # Creates an options hash suitable to pass to Jira::Client.new
    #
    # @example
    #   config = IssueScheduler::Config.new(<<~YAML)
    #     username: jcouball
    #     password: my_password
    #     site: https://jira.example.com
    #     context_path: ''
    #     auth_type: basic
    #     issue_files: '~/scheduled_issues/**/*.yaml'
    #   YAML
    #   config.to_jira_options #=> {
    #     username: 'jcouball',
    #     password: 'my_password',
    #     site: 'https://jira.example.com',
    #     context_path: '',
    #     auth_type: 'basic'
    #   }
    #
    # @return [Hash] the options hash
    #
    def to_jira_options
      config.slice(:username, :password, :site, :context_path, :auth_type)
    end

    private

    # Raise a RuntimeError if the config is not a Hash
    # @raise [RuntimeError] if the config is invalid
    # @return [Void]
    # @api private
    def assert_config_is_an_object(config_hash)
      raise "YAML config is not an object, contained '#{config_hash}'" unless
        config_hash.is_a?(Hash)
    end

    # Raise a RuntimeError if the config contains unexpected keys
    # @raise [RuntimeError] if the config is invalid
    # @return [Void]
    # @api private
    def assert_no_unexpected_keys(config_hash)
      unexpected_keys = config_hash.keys - DEFAULT_VALUES.keys
      raise "Unexpected configuration keys : #{unexpected_keys}" unless
        unexpected_keys.empty?
    end

    # Raise a RuntimeError if the config contains a nil value
    # @raise [RuntimeError] if the config is invalid
    # @return [Void]
    # @api private
    def assert_all_values_are_non_nil(config_hash)
      keys_of_missing_values = config_hash.select { |_k, v| v.nil? }.keys
      raise "Missing configuration values: #{keys_of_missing_values}" unless
        keys_of_missing_values.empty?
    end

    # Reads the config file returning a hash
    # @raise [RuntimeError] if the config file can not be read or is not valid
    # @return [Hash<String, String] the config hash read from config_yaml
    # @api private
    def parse_config(config_yaml)
      YAML.safe_load(config_yaml, permitted_classes: [Symbol], aliases: true, symbolize_names: true)
    rescue Psych::SyntaxError => e
      raise "Error parsing YAML config: #{e.message}"
    end

    # The config hash from config_yaml
    # @return [Hash] the config hash
    # @api private
    attr_reader :config

    # Defines the allows keys and default values for each key
    #
    # A nil value indicates that the key does not have a default value and must
    # be specified in the config_yaml.
    #
    # @return [Hash] the allows keys and their default values
    # @api private
    DEFAULT_VALUES = {
      username: nil,
      password: nil,
      site: nil,
      context_path: '',
      auth_type: 'basic',
      issue_files: '~/.issue_scheduler/issue_files'
    }.freeze
  end
end
