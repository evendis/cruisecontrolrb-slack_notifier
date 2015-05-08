# Slack Notifier Plugin for CruiseControl.rb

This is a quick-and-dirty port of
[cruisecontrolrb-campfire_notifier](https://github.com/h3h/cruisecontrolrb-campfire_notifier)
to add [slack](https://slack.com) notifications
for (very) old versions of [CruiseControl.rb](http://cruisecontrolrb.thoughtworks.com/).

This plugin will post notifications to a Slack channel when a build on CC.rb
finishes. By default, it will alert the room when a build is: FIXED (was
previously failing, now passing), BROKEN (was previously passing, now failing),
SUCCESS and FAILED.

## Installation

### Getting the Software

Clone this repo into a suitable directory:

    $ cd ~
    $ git clone https://github.com/evendis/cruisecontrolrb-slack_notifier
    $ cd cruisecontrolrb-slack_notifier

### Installing the Plugin

Find your `$CRUISE_HOME/builder_plugins` directory (usually
`~/.cruise/builder_plugins`), then symlink to `lib/slack_notifier.rb` within
this plugin:

    $ cd ~/.cruise/builder_plugins
    $ ln -s ~/cruisecontrolrb-slack_notifier/lib/slack_notifier.rb

You should end up with something like:

    # cd ~/.cruise
    $ tree -L 2
    .
    |-- builder_plugins
    |   `-- slack_notifier.rb -> /Users/brad/cruisecontrolrb-slack_notifier/lib/slack_notifier.rb
    |-- data.version
    |-- projects
    |   `-- myproject
    |-- site.css
    `-- site_config.rb

## Configuration

Inside each of your project directories (`~/.cruise/projects/myproject/`)
you'll find a `cruise_config.rb` file. For each project that you want to
set up to notify Campfire, configure it with the following:

    Project.configure do |project|
      project.slack_notifier.url                   = 'myaccount'
      project.slack_notifier.token                 = 'secret'
      project.slack_notifier.channel               = 'builds'

      # Optional:
      project.campfire_notifier.only_failed_builds    = true
      project.campfire_notifier.only_first_failure    = true
      project.campfire_notifier.only_fixed_and_broken_builds = true
    end

These configuration options should be pretty self-explanatory.

Or not.. here's the chart of when notifications are enabled/disabled:

    +------------------------------+------------------+----------------+------------------+----------------+
    |                              | was broke now ok | success        | was ok now broke | broken         |
    | when flag=true               | build_fixed      | build_finished | build_broken     | build_finished |
    +------------------------------+------------------+----------------+------------------+----------------+
    | (none - default)             |       no         |   yes          |       no         |  yes           |
    | only_failed_builds           |       no         |   no           |       no         |  yes           |
    | only_first_failure           |       no         |   yes          |       yes        |  no            |
    | only_fixed_and_broken_builds |       yes        |   no           |       yes        |  no            |
    +------------------------------+------------------+----------------+------------------+----------------+


