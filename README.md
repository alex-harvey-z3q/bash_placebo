# Placebo for Bash

[![Build Status](https://img.shields.io/travis/alexharv074/bash_placebo.svg)](https://travis-ci.org/alexharv074/bash_placebo)

The Bash Placebo library is inspired by Mitch Garnaat's Python library of the [same name](https://github.com/garnaat/placebo).

It allows you to call AWS CLI commands and retrieve responses that look like real AWS CLI responses from a file-based data store. This allows you to unit test your AWS CLI shell scripts without needing to hit a real AWS account.

## Installation

The tool can be installed just by copying the script from the master branch into your path somewhere. E.g.

~~~ text
$ curl -o /usr/local/bin/placebo \
    https://raw.githubusercontent.com/alexharv074/bash_placebo/master/placebo
~~~

## Quickstart

Using record mode to save response in a file `shunit2/fixtures/aws.sh`:

~~~ bash
. placebo
pill_attach command=aws data_path=shunit2/fixtures/aws.sh
pill_record
~~~

Reading those responses back in the context of your unit tests:

~~~ bash
. placebo
pill_attach command=aws data_path=shunit2/fixtures/aws.sh
pill_playback
~~~

Also, be sure to call the `pill_detach` function during tear-down:

~~~ bash
tearDown() {
  pill_detach
}
~~~

## Code example

A full working example of tests in the shunit2 framework that use this library can be found [here](https://github.com/alexharv074/shunit2_example).

## Recording responses

Recording the responses you need to test the AWS CLI shell script you are working on is easy.

From the CLI:

~~~ text
$ . placebo
$ pill_attach command=aws data_path=shunit2/fixtures/aws.sh
$ pill_record
~~~

The first line includes the Placebo functions in the running shell, including an `aws` function that replaces the external Python AWS CLI script. Then we tell Placebo where to save the responses, and set it to record mode.

Next, we source the script under test into the running shell too, like this:

~~~ text
$ . script_under_test some_arg some_other_arg
~~~

The script will appear to run as normal, but afterwards, responses from its calls to the AWS CLI are save in the data path.

## Manual mocking

If you want to create fake responses manually that can be read in later by Placebo, it is quite simple. They are formatted as case statements. For example:

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

## Spies

A log of all commands can be obtained using the `pill_log` function, allowing the mocks to be "spies" on AWS CLI commands called.

~~~ bash
testCommandsLogged() {
  . $script_under_test
  assertEquals "$(<expected_log)" "$(pill_log)"
}
~~~

## Contributing

PRs are welcome. To run the tests:

~~~ text
$ bash shunit2/placebo.sh
~~~

Support is available so feel free to raise issues.
