# IssueScheduler

Create new Jira issues on a cron like scheduler

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'issue_scheduler'
```

And then execute:

```shell
$ bundle install
...
Installing issue_scheduler 5.14.1
...
$
```

Or install it yourself as:

```ruby
$ gem install issue_scheduler
...
$
```

## Usage

### Configuration

Add config in the following format to ~/.issue_scheduler.yaml:

```text
username: your_username
password: Qwerty13456!
site: https://jira.mydomain.com/
context_path: ""
auth_type: :basic
issue_templates: ~/issue_templates/**/*.yaml
```

Place issue templates in the issue_templates subdirectory. Each teamplate is a yaml
file in the following format:

```text
recurrance_rule: 'RRULE:FREQ=WEEKLY;BYDAY=MO,WE,FR'
project: JIRAPROJECT
component: Internal
type: Story
summary: Take out the trash
description: |
  Remember to take out the trash in the following rooms:
  * Kitchen
  * Bathroom
  * Bedroom
  * Laundry Room

  When you finish this task, you will feel a lot better!
```

### Running the Scheduler

Once configuration is finished, run the scheduyler with the following command:

```shell
issue-scheduler
```

Press CTRL-C to exit the scheduler.

### Running the Admin UI

Run the admin UI with the following command:

```shell
issue-scheduler-admin-ui
```

Press CTRL-C to exit the admin UI.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake`
to run the tests. You can also run `bin/console` for an interactive prompt that will
allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To
release a new version, update the version number in `version.rb`, and then run
`bundle exec rake release`, which will create a git tag for the version, push git
commits and the created tag, and push the `.gem` file to
[rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at [jcouball/issue_scheduler](https://github.com/jcouball/issue_scheduler).
