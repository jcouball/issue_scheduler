<!--
# @markup markdown
# @title Change Log
-->

# Change Log

The full change log is stored on [this project's GitHub releases page](https://github.com/jcouball/issue_scheduler).

## v0.1.1

* 21efe6f Correctly set allowed_push_host in gemspec
* 9e1a722 Create initial CHANGELOG.md
* 559d3a3 Add changelog-rs Dockerfile
* 37ef841 Use gh to get repo web url instead of hardcoding the url
* d007d5f Add JRuby support to build and checkout yard from head
* 1b62347 Exclude vendor/bundle/**/* from rubocop
* 1c15d36 Exclude bin/create-release from rubocop
* 5456538 Add build and release scripts
* a66e8f8 Fix Markdown lint offenses
* cc807ac Add more usage documentation in the README.md
* 8bd404d Only require Ruby 2.7
* 6665fc0 Add script that shows example for creating an issue
* 87d893d Refactor the server script to make Rubocop happy
* c500c95 Add Config#load_issue_templates
* b9d482a Refactor reading and parsing YAML
* 0b5225b Add lib_dir method
* 725f7ee Create the script to start the admin ui
* dfbdfa2 Create the main issue-scheduler service start script
* b049b13 Rename Config#issue_files to Config#issue_templates
* 4ebb1fd Refactor IssueTemplate to use ActiveRecord
* dab32f8 Add template_name to IssueTemplate
* bf8c835 Add the IssueTemplate class
* 5dd23a0 Remove Gemfile.lock from git
* 6bd612b Documentation cleanup
* ba1564a Refactor config to take a YAML string instead of a filename
* ae393bc Add the IssueScheduler::Config class
* 32219f2 List undocumented objects in the yard task

See https://github.com/jcouball/issue_scheduler/releases/tag/v0.1.1

## v0.1.0

* caad020 Initial version
