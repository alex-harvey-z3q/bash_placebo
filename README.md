# Placebo for Bash

The Bash Placebo library is inspired by the Python [library](https://github.com/garnaat/placebo) of the same name by Mitch Garnaat.

It allows you to call the AWS CLI commands and retrieve responses that look like real AWS CLI responses that come from a data store. This allows you to unit test your AWS CLI shell scripts without needing to hit the AWS.

## Installation

For now, the tool is installed just by copying the script from the master branch into your path somewhere. E.g.

~~~ text
$ curl https://raw.githubusercontent.com/alexharv074/bash_placebo/master/placebo -o /usr/local/bin/placebo
~~~

## Quickstart

Using record mode to generate fake responses in the shunit2/fixtures directory:

~~~ bash
. placebo
pill_attach aws shunit2/fixtures
pill_record
~~~

Reading these responses back in your unit tests:

~~~ bash
. placebo
pill_attach aws shunit2/fixtures
pill_playback
~~~

A working example of tests in the shunit2 framework that uses this library can be found [here](https://github.com/alexharv074/shunit2_example).

## Manual mocking

If you want to create fake responses to be read back in manually, they are very simple.

1. Ensure that the file is named `command.subcommand.n`. Placebo reads in the nth file each time the aws _command subcommand_ command is called. This is also how the Python library works.
2. The file should contain a case statement like:

~~~ bash
case "aws $*" in
'aws command subcommand other args')
  echo some_response
  ;;
esac
~~~

## Contributing

Run the tests:

~~~ text
$ bash shunit2/placebo.sh
~~~

Feedback is welcome and support is available.
