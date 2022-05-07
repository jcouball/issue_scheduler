# frozen_string_literal: true

require 'active_model'
require 'active_model_persistence'

require 'pp'
require 'fugit'

module IssueScheduler
  # A template for an issue
  #
  # @example Create a new issue template specifying all attributes
  #   attributes = {
  #     name: 'weekly_status_report.yaml',
  #     cron: '0 7 * * 6', # every Friday at 7:00 AM
  #     project: 'MYJIRA',
  #     component: 'Management',
  #     type: 'Story',
  #     summary: 'Weekly status report',
  #     description: "Update the weekly status report\n\nhttp://mydomain.com/status",
  #     due_date: '2022-05-06'
  #   }
  #
  #   template = IssueScheduler::IssueTemplate.new(attributes)
  #
  # @example Create a new issue template specifying only required attributes
  #   attributes = {
  #     name: 'weekly_status_report.yaml',
  #     cron: '0 7 * * 6', # every Friday at 7:00 AM
  #     project: 'MYJIRA',
  #     summary: 'Weekly status report',
  #   }
  #
  #   template = IssueScheduler::IssueTemplate.new(attributes)
  #
  # @api public
  class IssueTemplate
    include ActiveModelPersistence::Persistence
    include ActiveModel::Validations::Callbacks

    # @!attribute [rw] name
    # The template name
    #
    # * name must not be present
    # * name must be unique across all IssueTemplate objects
    #
    # @example
    #   template.name #=> "weekly_status_report"
    #
    # @return [String] the template name
    #
    # @api public

    attribute :name, :string
    validates :name, presence: true

    # @!attribute [rw] cron
    # A cron string that specifies when the issue should be created
    #
    # * cron must be present
    # * cron must be a valid cron string
    #
    # @example
    #   # 7 AM Monday - Friday
    #   template.cron #=> "0 7 * * 1,2,3,4,5"
    #
    # @return [String] the cron string
    #
    # @see https://github.com/floraison/fugit The fugit gem
    #
    # @api public

    attribute :cron, :string
    validates :cron, presence: true
    validates_each :cron do |record, attr, value|
      record.errors.add(attr, 'is not a valid cron string') unless Fugit.parse_cron(value)
    end

    # @!attribute [rw] project
    # The JIRA project name
    #
    # * project must be present
    # * project is upcased
    #
    # @example
    #   template.project #=> "MYPROJECT"
    #
    # @return [String] the project name
    #
    # @api public

    attribute :project, :string
    validates :project, presence: true

    def project=(project)
      super(project.is_a?(String) ? project.upcase : project)
    end

    # @!attribute [rw] component
    # The JIRA component name
    #
    # * component is optional and defaults to nil
    # * component may be nil but not an empty string
    #
    # The component name is optional and will be set to nil if not given.
    #
    # @example
    #   template.component #=> "MYCOMPONENT"
    #
    # @return [String] the component name
    #
    # @api public

    attribute :component, :string, default: nil
    validates :component, presence: true, allow_nil: true

    # @!attribute [rw] summary
    # The JIRA issue summary
    #
    # * summary must be present
    #
    # @example
    #   template.summary #=> "Take out the trash"
    #
    # @return [String] the JIRA issue summary
    #
    # @api public

    attribute :summary, :string
    validates :summary, presence: true

    # @!attribute [rw] description
    # The JIRA issue description
    #
    # * description is optional and defaults to nil
    # * description may be nil but not an empty string
    #
    # @example
    #   template.description #=> "Take out the trash in:\n- kitchen\n- bathroom\n- bedroom"
    #
    # @return [String] the JIRA issue description
    #
    # @api public

    attribute :description, :string, default: nil
    validates :description, presence: true, allow_nil: true

    # @!attribute [rw] type
    # The name of the JIRA issue type
    #
    # * type is optional and defaults to nil
    # * type may be nil but not an empty string
    #
    # @example
    #   template.type #=> "Story"
    #
    # @return [String] the JIRA issue type
    #
    # @api public

    attribute :type, :string, default: nil
    validates :type, presence: true, allow_nil: true

    # @!attribute [rw] due_date
    # The JIRA issue due date
    #
    # * due_date is optional and defaults to nil
    # * If non-nil, due_date must be a Date object or parsable by Date.parse
    #
    # @example
    #   template.due_date #=> #<Date: 2022-05-03 ((2459703j,0s,0n),+0s,2299161j)>
    #
    # @return [Date, nil] the JIRA issue description
    #
    # @api public

    attribute :due_date, :date
    validates :due_date, presence: true, allow_nil: true

    validates_each :due_date do |record, attr, value|
      before_type_cast = record.due_date_before_type_cast
      record.errors.add(attr, "'#{before_type_cast}' is not a valid date") if value.nil? && !before_type_cast.nil?
    end

    def due_date=(date)
      @due_date_before_type_cast = date
      super(date)
    end

    # Sets the primary key to `:name`
    # @return [Symbol] the attribute name of the primary key
    # @api private
    def self.primary_key
      :name
    end

    # The due_date supplied by the user since ActiveModel sets it to nil of invalid
    # @return [Date, String, nil] the due_date before type cast
    # @api private
    attr_reader :due_date_before_type_cast

    # private

    # Create a new issue template from the given template_yaml
    #
    # @example
    #   template_yaml = <<~YAML
    #     template_name: Take out the trash
    #     cron: '0 7 * * 1,2,3,4,5 America/Los_Angeles' # Mon-Fri, 7 AM UTC
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

    # Define getter methods for allowed keys
    # ATTRIBUTES.each do |key, _value|
    #   define_method(key) do
    #     template[__method__]
    #   end
    # end

    # private

    # The template Hash read from YAML
    # @return [Hash]
    # @api private
    # attr_reader :template

    # Reads the config file returning a hash
    # @raise [RuntimeError] if the config file can not be read or is not valid
    # @return [Hash<String, String] the config hash read from config_yaml
    # @api private
    # def parse_template(template_yaml)
    #   YAML.safe_load(template_yaml, permitted_classes: [Symbol, Date], aliases: true, symbolize_names: true)
    # rescue Psych::SyntaxError => e
    #   raise "Error parsing YAML template: #{e.message}"
    # end

    # Set default values for keys that are not given in the template
    #
    # @param template_from_yaml [Hash] the template from YAML
    # @return [Hash] the template with default values
    # @api private
    # def template_with_default_values(template_from_yaml)
    #   template = {}
    #   ATTRIBUTES.each { |k, v| template[k] = v[:default] if v.key?(:default) }
    #   template.merge!(template_from_yaml)
    # end

    # Run the conversion functions for values that are given in the template
    #
    # @return [Void] the template is modified in place
    # @api private
    # def run_value_conversions!
    #   template.each do |key, value|
    #     if (conversion = ATTRIBUTES.dig(key, :conversion))
    #       template[key] = conversion.call(value)
    #     end
    #   end
    # end

    # Raise a RuntimeError if any validation method returns false
    #
    # @raise [RuntimeError] if the config is invalid
    # @return [Void]
    # @api private
    # def assert_all_values_are_valid
    #   template.each do |key, value|
    #     if (validation = ATTRIBUTES.dig(key, :validation)) && !validation.call(value)
    #       raise "Invalid value for #{key}: #{value.pretty_inspect}"
    #     end
    #   end
    # end

    # Raise a RuntimeError if the config is not a Hash
    # @raise [RuntimeError] if the config is invalid
    # @return [Void]
    # @api private
    # def assert_template_is_an_object(template_from_yaml)
    #   raise "YAML issue template is not an object, contained '#{template_from_yaml}'" unless
    #     template_from_yaml.is_a?(Hash)
    # end

    # Raise a RuntimeError if the config contains unexpected keys
    # @raise [RuntimeError] if the config is invalid
    # @return [Void]
    # @api private
    # def assert_no_unexpected_keys
    #   unexpected_keys = template.keys - ATTRIBUTES.keys
    #   raise "Unexpected issue template keys: #{unexpected_keys}" unless
    #     unexpected_keys.empty?
    # end

    # Raise a RuntimeError if the config contains a nil value
    # @raise [RuntimeError] if the config is invalid
    # @return [Void]
    # @api private
    # def assert_all_required_keys_are_given
    #   required_attributes = ATTRIBUTES.select { |_, v| v[:required] }.keys
    #   missing_keys = required_attributes - template.keys
    #   raise "Missing issue template keys: #{missing_keys}" unless
    #     missing_keys.empty?
    # end
  end
end
