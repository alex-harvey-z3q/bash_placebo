# Placebo for Bash

The Bash Placebo library is inspired by Mitch Garnaat's Python [library](https://github.com/garnaat/placebo) of the same name.

It allows you to call AWS CLI commands and retrieve responses that look like real AWS CLI responses from a file-based data store. This allows you to unit test your AWS CLI shell scripts without needing to hit the real AWS.

## Installation

For now, the tool is installed just by copying the script from the master branch into your path somewhere. E.g.

~~~ text
$ curl -o /usr/local/bin/placebo \
    https://raw.githubusercontent.com/alexharv074/bash_placebo/master/placebo
~~~

## Quickstart

Use record mode to generate fake responses in a file shunit2/fixtures/aws.sh:

~~~ bash
. placebo
pill_attach aws=/usr/local/bin/aws data_path=shunit2/fixtures/aws.sh
pill_record
~~~

Read these responses back in your unit tests:

~~~ bash
. placebo
pill_attach aws=/usr/local/bin/aws data_path=shunit2/fixtures/aws.sh
pill_playback
~~~

A working example of tests in the shunit2 framework that uses this library can be found [here](https://github.com/alexharv074/shunit2_example).

## Manual mocking

If you want to create fake responses to be read back in manually, they are very simple. For example:

~~~ bash
case "aws $*" in
'aws command subcommand some args')
  echo some_response
  ;;
'aws command subcommand some other args')
  echo some_other_response
  ;;
esac
~~~

## Spies and cleanup

A log of all commands can be obtained using the `pill_log` function so that you can "spy" on the AWS CLI commands called:

Note that it is then up to you to clean up the `commands_log` file in your tests:

~~~ bash
testCommandsLogged() {
  . $script_under_test
  assertEquals "$(<expected_log)" "$(pill_log)"
}

tearDown() {
  pill_cleanup
}
~~~

## Contributing

PRs are welcome. To run the tests:

~~~ text
$ bash shunit2/placebo.sh
~~~

Support is available so feel free to raise issues.
