#!/usr/bin/env bash

setUp() {
  echo "#!/usr/bin/env bash
echo foo
" > /tmp/aws ; chmod +x /tmp/aws
  echo "#!/usr/bin/env bash
echo bar
" > /tmp/curl ; chmod +x /tmp/curl
  echo "#!/usr/bin/env bash
echo
" > /tmp/baz ; chmod +x /tmp/baz

  PATH="/tmp:$PATH"
  export PATH
}

tearDown() {
  rm -f \
    /tmp/aws \
    /tmp/curl \
    shunit2/fixtures/curl.sh \
    expected_content

  type -t pill_detach > /dev/null && pill_detach ; true
}

oneTimeTearDown() {
  git checkout shunit2/fixtures/aws.sh
}

testDetach() {
  set | sed '
    /^_=testDetach/d' > before
  . placebo
  pill_attach "command=aws,curl" "data_path=shunit2/fixtures"
  pill_playback
  pill_detach
  set | sed '
    /^_=/d
    /^BASH_REMATCH=/d' > after
  assertEquals "pill_detach is leaving variables or functions behind" "" "$(diff -wu before after)"
  rm -f before after
}

testPlayback() {
  . placebo
  pill_attach "command=aws" "data_path=shunit2/fixtures"
  pill_playback
  response=$(aws autoscaling describe-auto-scaling-groups)
  assertEquals "response" "$response"
}

testRecord() {
  . placebo
  pill_attach "command=aws" "data_path=shunit2/fixtures"
  pill_record

  OLDPATH=$PATH
  PATH=/tmp:$PATH

  command_to_run="aws ec2 run-instances --image-id foo"
  $command_to_run > /dev/null
  cat > expected_content <<EOD
case "aws \$*" in
'aws autoscaling describe-auto-scaling-groups')
  cat <<'EOF'
response
EOF
  ;;
'$command_to_run') echo 'foo' ;;
*)
  echo "No responses for: aws \$*" | tee -a unknown_commands
  ;;
esac
EOD

  assertEquals "" "$(diff -wu expected_content "$DATA_PATH"/aws.sh)"
  # shellcheck disable=SC2086
  assertEquals "foo" "$(bash /tmp/$command_to_run)"
  assertEquals "$command_to_run" "$(pill_log)"

  PATH=$OLDPATH
}

testRecordShortCommand() {
  . placebo
  pill_attach "command=aws" "data_path=shunit2/fixtures"
  pill_record

  OLDPATH=$PATH
  PATH=/tmp:$PATH

  command_to_run="aws help"
  $command_to_run > /dev/null
  cat > expected_content <<EOD
case "aws \$*" in
'aws autoscaling describe-auto-scaling-groups')
  cat <<'EOF'
response
EOF
  ;;
'aws ec2 run-instances --image-id foo') echo 'foo' ;;
'$command_to_run') echo 'foo' ;;
*)
  echo "No responses for: aws \$*" | tee -a unknown_commands
  ;;
esac
EOD

  assertEquals "" "$(diff -wu expected_content "$DATA_PATH"/aws.sh)"

  PATH=$OLDPATH
}

testRecordMultipleCommands() {
  . placebo
  pill_attach "command=aws,curl" "data_path=shunit2/fixtures"
  pill_record

  OLDPATH=$PATH
  PATH=/tmp:$PATH

  command_to_run="curl https://foo/bar/baz"
  $command_to_run > /dev/null
  cat > expected_content <<EOD
case "curl \$*" in
'$command_to_run') echo 'bar' ;;
*)
  echo "No responses for: curl \$*" | tee -a unknown_commands
  ;;
esac
EOD

  assertEquals "command 1 is not curl but '${COMMANDS[1]}'" "curl" "${COMMANDS[1]}"
  assertEquals "" "$(diff -wu expected_content "$DATA_PATH"/curl.sh)"
  # shellcheck disable=SC2086
  assertEquals "bar" "$(bash /tmp/$command_to_run)"
  assertEquals "$command_to_run" "$(pill_log)"

  PATH=$OLDPATH
}

testNonexistentCommands() {
  . placebo
  response=$(pill_attach "command=aws,curl,foobarbaz" "data_path=shunit2/fixtures" | head -1)
  assertEquals \
    "command 'foobarbaz' not found" \
    "$response"
}

testDataPathIsNotADir() {
  . placebo
  response=$(pill_attach "command=aws" "data_path=shunit2/fixtures/aws.sh" | head -1)
  assertEquals \
    "DATA_PATH should be a directory" \
    "$response"
}

testPillNotSet() {
  . placebo
  pill_attach "command=aws" "data_path=shunit2/fixtures"
  response=$(aws ec2 run-instances)
  assertEquals \
    "PILL must be set to playback or record. Try pill_playback or pill_record" \
    "$response"
}

testDataPathNotSet() {
  . placebo
  pill_attach "command=aws" "data_path=shunit2/fixtures"
  pill_playback
  unset DATA_PATH # not sure why this line is required.
  response=$(aws ec2 run-instances)
  assertEquals \
    "DATA_PATH must be set. Try pill_attach" "$response"
}

testExecutePlacebo() {
  response=$(bash placebo)
  assertTrue "Usage message not seen" "grep -q Usage <<< $response"
}

testMainUsage() {
  response=$(. placebo -h)
  assertEquals "Usage: . shunit2/placebo.sh [-h]" "$response"
  . placebo
}

testPillFunctionUsage() {
  . placebo
  response=$(pill_playback -h)
  assertEquals "Usage: pill_playback [-h]
Sets Placebo to playback mode" "$response"
}

endToEndTestFunction() {
  dir='/tmp/foo'
  touch "$dir"
  response=$(ls -l "$dir")
  echo "$response"
  rm -f "$dir"
}

testEndToEnd() {
  response0="$(endToEndTestFunction)"

  . placebo
  pill_attach "command=touch,ls,rm" "data_path=shunit2/fixtures"
  pill_record
  response1="$(endToEndTestFunction)"
  pill_detach

  assertEquals "end to end test response in record mode differs from no placebo" "$response0" "$response1"

  . placebo
  pill_attach "command=touch,ls,rm" "data_path=shunit2/fixtures"
  pill_playback
  response2="$(endToEndTestFunction)"
  pill_detach
  assertEquals "end to end test response in playback mode differs from record mode" "$response1" "$response2"

  command rm -f shunit2/fixtures/{touch,ls,rm}.sh
}

testExitStatusIsPreserved() {
  . placebo
  pill_attach "command=false" "data_path=shunit2/fixtures"
  pill_record
  false ; rc1="$?"
  assertEquals "mocked false returns exit status that is not 1" "1" "$rc1"
  pill_detach

  . placebo
  pill_attach "command=false" "data_path=shunit2/fixtures"
  pill_playback
  false ; rc2="$?"
  assertEquals "false is not a function" "function" "$(type -t false)"
  assertEquals "mocked false returns exit status that is not 1" "1" "$rc2"
  pill_detach

  command rm -f shunit2/fixtures/false.sh
}

testDemonstrateEchoBug() {
  response0="$(baz)"

  . placebo
  pill_attach "command=baz" "data_path=shunit2/fixtures"
  pill_record
  pill_detach

  . placebo
  pill_attach "command=baz" "data_path=shunit2/fixtures"
  pill_playback
  response1="$(baz)"
  pill_detach

  assertNotEquals "failed to demonstrate bug - is it fixed?" "$response0" "$response1"
}

. shunit2
