# frozen_string_literal: true

require 'yaml'

module IssueScheduler
  # Manage the configuration for the YCA EOL Dashboard program
  # @api public
  class Config
    # Create a new Config object reading from the config_file
    # @example
    #   config = Config.new('/path/to/config.yml')
    #
    # @param config_file [String] the path to the config file
    #
    #   File.expand path is called on config_file so you can pass
    #   in a relative path or a path that includes '~' for the
    #   current user's home directory.
    #
    def initialize(config_file = '~/.issue_scheduler.yaml')
      @config_file = Pathname.new(File.expand_path(config_file))
      @config = read_config
    end

    # The username to use when authenticating with Jira
    #
    # @example
    #   config = Config.new('/path/to/config.yml')
    #   config.username #=> 'jcouball'
    #
    # @return [String] the username
    #
    def username
      config['username']
    end

    # The password to use when authenticating with Jira
    #
    # @example
    #   config = Config.new('/path/to/config.yml')
    #   config.password #=> 'my_password'
    #
    # @return [String] the password
    #
    def password
      config['password']
    end

    # The URL of the Jira server
    #
    # @example
    #   config = Config.new('/path/to/config.yml')
    #   config.site #=> 'https://jira.example.com'
    #
    # @return [String] the Jira URL
    #
    def site
      config['site']
    end

    # The context path to append to the Jira server URL
    #
    # @example
    #   config = Config.new('/path/to/config.yml')
    #   config.context_path #=> ''
    #
    # @return [String] the context path
    #
    def context_path
      config['context_path']
    end

    # The authentication type to use when authenticating with Jira
    #
    # @example
    #   config = Config.new('/path/to/config.yml')
    #   config.auth_type #=> 'basic'
    #
    # @return ['basic', 'oauth'] the authentication type
    #
    def auth_type
      config['auth_type']
    end

    # The glob pattern to use to find issue files
    #
    # @example
    #   config = Config.new('/path/to/config.yml')
    #   config.issue_files #=> '~/scheduled_issues/**/*.yaml'
    #
    # @return [String] the glob pattern
    #
    # @see https://ruby-doc.org/core-3.1.2/Dir.html#method-c-glob Dir.glob
    #
    def issue_files
      config['issue_files']
    end

    private

    # Raise a RuntimeError if the config is not a Hash
    # @raise [RuntimeError] if the config is invalid
    # @return [Void]
    # @api private
    def assert_config_is_an_object(config_hash)
      raise "YAML config file '#{config_file}' is not an object, contained '#{config_hash}'" unless
        config_hash.is_a?(Hash)
    end

    # Raise a RuntimeError if the config contains unexpected keys
    # @raise [RuntimeError] if the config is invalid
    # @return [Void]
    # @api private
    def assert_no_unexpected_keys(config_hash)
      unexpected_keys = config_hash.keys - DEFAULT_VALUES.keys
      raise "Unexpected configuration keys in config file '#{config_file}': #{unexpected_keys}" unless
        unexpected_keys.empty?
    end

    # Raise a RuntimeError if the config contains a nil value
    # @raise [RuntimeError] if the config is invalid
    # @return [Void]
    # @api private
    def assert_all_values_are_non_nil(config_hash)
      keys_of_missing_values = config_hash.select { |_k, v| v.nil? }.keys
      raise "Missing configuration values in config file '#{config_file}': #{keys_of_missing_values}" unless
        keys_of_missing_values.empty?
    end

    # Raise a RuntimeError if the config file is not readable
    # @raise [RuntimeError] if the config can not be read or is not valid
    # @return [Hash] the validated config
    # @api private
    def read_config
      config_hash = read_config_file

      assert_config_is_an_object(config_hash)
      assert_no_unexpected_keys(config_hash)

      config_hash = DEFAULT_VALUES.merge(config_hash)

      assert_all_values_are_non_nil(config_hash)

      config_hash
    end

    # Reads the config file returning a hash
    # @raise [RuntimeError] if the config file can not be read or is not valid
    # @return [Hash<String, String] the config hash read from config_file
    # @api private
    def read_config_file
      YAML.load_file(config_file.to_s)
    rescue Psych::SyntaxError => e
      raise "Error parsing YAML config file '#{config_file}': #{e.message}"
    rescue Errno::ENOENT
      raise "Config file '#{config_file}' does not exist or is not readable"
    end

    # The config hash read from config_file
    # @return [Hash] the config hash
    # @api private
    attr_reader :config

    # The path to the config file set in the initializer
    # @return [Pathname] the path to the config file
    # @api private
    attr_reader :config_file

    # Defines the allows keys and default values for each key
    #
    # A nil value indicates that the key does not have a default value and must
    # be specified in the config_file.
    #
    # @return [Hash] the allows keys and their default values
    # @api private
    DEFAULT_VALUES = {
      'username' => nil,
      'password' => nil,
      'site' => nil,
      'context_path' => '',
      'auth_type' => 'basic',
      'issue_files' => '~/.issue_scheduler/issue_files'
    }.freeze
  end
end
