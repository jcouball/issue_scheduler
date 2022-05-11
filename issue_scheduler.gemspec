# frozen_string_literal: true

require_relative 'lib/issue_scheduler/version'

Gem::Specification.new do |spec|
  spec.name = 'issue_scheduler'
  spec.version = IssueScheduler::VERSION
  spec.authors = ['James Couball']
  spec.email = ['jcouball@yahoo.com']

  spec.summary = 'Schedule recurring Jira issue creation'
  spec.description = 'Allow Jira issues to be created at a specified recurrence'
  spec.homepage = 'https://github.com/jcouball/issue_scheduler'
  spec.required_ruby_version = '>= 2.7.0'
  spec.license = 'MIT'

  spec.metadata['allowed_push_host'] = 'rubygems.org'
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = File.join(spec.homepage, 'blob/master/CHANGELOG.md')

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'active_model_persistence', '~> 0.5.0'
  spec.add_dependency 'jira-ruby', '~> 2.2'
  spec.add_dependency 'sidekiq-cron', '~> 1.4'

  spec.add_development_dependency 'bump', '~> 0.10'
  spec.add_development_dependency 'bundler-audit', '~> 0.9'
  spec.add_development_dependency 'github_pages_rake_tasks', '~> 0.1'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rspec', '~> 3.11'
  spec.add_development_dependency 'rubocop', '~> 1.28'
  spec.add_development_dependency 'simplecov', '~> 0.21'
  spec.add_development_dependency 'solargraph'

  unless RUBY_PLATFORM == 'java'
    spec.add_development_dependency 'redcarpet', '~> 3.5'
    spec.add_development_dependency 'yard', '~> 0.9'
    spec.add_development_dependency 'yardstick', '~> 0.9'
  end

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
