# frozen_string_literal: true

require 'yaml'
require 'pp'
require 'rrule'

module IssueScheduler
  # A template for an issue
  # @api public
  class IssueTemplate
    # Create a new issue template from the given template_yaml
    #
    # @example
    #   template_yaml = <<~YAML
    #     template_name: Take out the trash
    #     recurrance_rule: 'RRULE:FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR'
    #     project: 'MYPROJECT'
    #     component: 'Internal'
    #     summary: 'Take out the trash'
    #     description: |
    #       Take out the trash in the following rooms:
    #       - kitchen
    #       - bathroom
    #       - bedroom
    #     type: 'Story'
    #     due_date: '2022-05-03'
    #   YAML
    #
    #   template = IssueScheduler::IssueTemplate.new(template_yaml)
    #   template.recurrance_rule #=> "FREQ=WEEKLY;INTERVAL=1;BYDAY=MO,TU,WE,TH,FR"
    #
    # @param template_yaml [String] the YAML string to parse
    #
    def initialize(template_yaml)
      template_from_yaml = parse_template(template_yaml)
      assert_template_is_an_object(template_from_yaml)
      @template = template_with_default_values(template_from_yaml)
      assert_no_unexpected_keys
      assert_all_required_keys_are_given
      assert_all_values_are_valid
      run_value_conversions!
    end

    # Attributes in this array must be given in the YAML template
    REQUIRED_ATTRIBUTES = %i[template_name recurrance_rule project summary].freeze

    # Defines the attributes for this object
    #
    # A getter method is created for each key in this HASH
    ATTRIBUTES = {
      template_name: {
        validation: ->(v) { v.is_a?(String) && !v.empty? }
      },
      recurrance_rule: {
        validation:
          lambda do |v|
            v.is_a?(RRule) || (v.is_a?(String) && RRule.parse(v))
          rescue RRule::InvalidRRule
            false
          end,
        conversion: ->(v) { v.is_a?(RRule) ? v : RRule.parse(v) }
      },
      project: {
        validation: ->(v) { v.is_a?(String) && !v.empty? },
        conversion: ->(v) { v.upcase }
      },
      component: {
        default: nil,
        validation: ->(v) { v.nil? || (v.is_a?(String) && !v.empty?) }
      },
      summary: {
        validation: ->(v) { v.is_a?(String) && !v.empty? }
      },
      description: {
        default: nil,
        validation: ->(v) { v.nil? || (v.is_a?(String) && !v.empty?) }
      },
      type: {
        default: nil,
        validation: ->(v) { v.nil? || (v.is_a?(String) && !v.empty?) }
      },
      due_date: {
        default: nil,
        validation:
          lambda do |v|
            v.nil? || v.is_a?(Date) || (v.is_a?(String) && !v.empty? && Date.parse(v))
          rescue TypeError, Date::Error
            false
          end,
        conversion: ->(d) { d.is_a?(String) ? Date.parse(d) : d }
      }
    }.freeze

    # @!attribute [r] recurrance_rule
    # An iCalendar RRULE string defining when an issue should be created
    #
    # @example
    #   template.recurrence_rule #=> "FREQ=WEEKLY;INTERVAL=1;BYDAY=MO,TU,WE,TH,FR"
    #
    # @return [String] the RRULE string
    #
    # @see https://github.com/square/ruby-rrule The RRULE gem for more information
    #
    # @api public

    # @!attribute [r] project
    # The JIRA project name
    #
    # The project name is required and is upcased.
    #
    # @example
    #   template.project #=> "MYPROJECT"
    #
    # @return [String] the project name
    #
    # @api public

    # @!attribute [r] component
    # The JIRA component name
    #
    # The component name is optional and will be set to nil if not given.
    #
    # @example
    #   template.component #=> "MYCOMPONENT"
    #
    # @return [String] the component name
    #
    # @api public

    # @!attribute [r] summary
    # The JIRA issue summary
    #
    # The summary is required.
    #
    # @example
    #   template.summary #=> "Take out the trash"
    #
    # @return [String] the JIRA issue summary
    #
    # @api public

    # @!attribute [r] description
    # The JIRA issue description
    #
    # description is optional and set to nil if not given.
    #
    # @example
    #   template.description #=> "Take out the trash in:\n- kitchen\n- bathroom\n- bedroom"
    #
    # @return [String] the JIRA issue description
    #
    # @api public

    # @!attribute [r] type
    # The name of the JIRA issue type
    #
    # type is required.
    #
    # @example
    #   template.type #=> "Story"
    #
    # @return [String] the JIRA issue type
    #
    # @api public

    # @!attribute [r] due_date
    # The JIRA issue due date
    #
    # The due date is optional and will be set to nil if not given.
    #
    # @example
    #   template.due_date #=> #<Date: 2022-05-03 ((2459703j,0s,0n),+0s,2299161j)>
    #
    # @return [Date, nil] the JIRA issue description
    #
    # @api public

    # Define getter methods for allowed keys
    ATTRIBUTES.each do |key, _value|
      define_method(key) do
        template[__method__]
      end
    end

    private

    # The template Hash read from YAML
    # @return [Hash]
    # @api private
    attr_reader :template

    # Reads the config file returning a hash
    # @raise [RuntimeError] if the config file can not be read or is not valid
    # @return [Hash<String, String] the config hash read from config_yaml
    # @api private
    def parse_template(template_yaml)
      YAML.safe_load(template_yaml, permitted_classes: [Symbol, Date], aliases: true, symbolize_names: true)
    rescue Psych::SyntaxError => e
      raise "Error parsing YAML template: #{e.message}"
    end

    # Set default values for keys that are not given in the template
    #
    # @param template_from_yaml [Hash] the template from YAML
    # @return [Hash] the template with default values
    # @api private
    def template_with_default_values(template_from_yaml)
      template = {}
      ATTRIBUTES.each { |k, v| template[k] = v[:default] if v.key?(:default) }
      template.merge!(template_from_yaml)
    end

    # Run the conversion functions for values that are given in the template
    #
    # @return [Void] the template is modified in place
    # @api private
    def run_value_conversions!
      template.each do |key, value|
        if (conversion = ATTRIBUTES.dig(key, :conversion))
          template[key] = conversion.call(value)
        end
      end
    end

    # Raise a RuntimeError if any validation method returns false
    #
    # @raise [RuntimeError] if the config is invalid
    # @return [Void]
    # @api private
    def assert_all_values_are_valid
      template.each do |key, value|
        if (validation = ATTRIBUTES.dig(key, :validation)) && !validation.call(value)
          raise "Invalid value for #{key}: #{value.pretty_inspect}"
        end
      end
    end

    # Raise a RuntimeError if the config is not a Hash
    # @raise [RuntimeError] if the config is invalid
    # @return [Void]
    # @api private
    def assert_template_is_an_object(template_from_yaml)
      raise "YAML issue template is not an object, contained '#{template_from_yaml}'" unless
        template_from_yaml.is_a?(Hash)
    end

    # Raise a RuntimeError if the config contains unexpected keys
    # @raise [RuntimeError] if the config is invalid
    # @return [Void]
    # @api private
    def assert_no_unexpected_keys
      unexpected_keys = template.keys - ATTRIBUTES.keys
      raise "Unexpected issue template keys: #{unexpected_keys}" unless
        unexpected_keys.empty?
    end

    # Raise a RuntimeError if the config contains a nil value
    # @raise [RuntimeError] if the config is invalid
    # @return [Void]
    # @api private
    def assert_all_required_keys_are_given
      missing_keys = REQUIRED_ATTRIBUTES - template.keys
      raise "Missing issue template keys: #{missing_keys}" unless
        missing_keys.empty?
    end
  end
end
