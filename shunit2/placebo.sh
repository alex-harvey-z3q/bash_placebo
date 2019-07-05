#!/usr/bin/env bash

setUp() {
  . placebo
  pill_attach "command=aws" "data_path=shunit2/fixtures"
}

tearDown() {
  rm -f /tmp/aws
  rm -f "shunit2/fixtures/test.sh"
  rm -f expected_content
  type -t pill_detach > /dev/null && pill_detach ; true
}

oneTimeTearDown() {
  git checkout shunit2/fixtures/aws.sh
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

  echo "#!/usr/bin/env bash
echo foo
" > /tmp/aws ; chmod +x /tmp/aws

  command_to_run="aws ec2 run-instances --image-id foo"
  $command_to_run > /dev/null
  cat > expected_content <<EOD
case "aws \$*" in
'aws autoscaling describe-auto-scaling-groups')
  cat <<'EOF'
response
EOF
  ;;
'$command_to_run')
  cat <<'EOF'
foo
EOF
  ;;
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

  echo "echo foo" > /tmp/aws ; chmod +x /tmp/aws

  command_to_run="aws help"
  $command_to_run > /dev/null
  cat > expected_content <<EOD
case "aws \$*" in
'aws autoscaling describe-auto-scaling-groups')
  cat <<'EOF'
response
EOF
  ;;
'aws ec2 run-instances --image-id foo')
  cat <<'EOF'
foo
EOF
  ;;
'$command_to_run')
  cat <<'EOF'
foo
EOF
  ;;
*)
  echo "No responses for: aws \$*" | tee -a unknown_commands
  ;;
esac
EOD

  assertEquals "" "$(diff -wu expected_content "$DATA_PATH"/aws.sh)"

  PATH=$OLDPATH
}

testDataPathIsNotADir() {
  . placebo
  response=$(pill_attach "command=aws" "data_path=shunit2/fixtures/aws.sh" | head -1)
  assertEquals \
    "DATA_PATH should be a path to a directory" \
    "$response"
}

testPillNotSet() {
  . placebo
  response=$(aws ec2 run-instances)
  assertEquals \
    "PILL must be set to playback or record. Try pill_playback or pill_record" \
    "$response"
}

testDataPathNotSet() {
  . placebo
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

testDetach() {
  funcs="_usage
pill_attach
pill_playback
pill_record
pill_log
pill_detach
_cli_to_comm
_comm_to_file
_create_new
_update_existing
_filter
_record"
  . placebo
  pill_detach
  for f in $funcs ; do
    assertFalse "function $f is still defined" "type $f"
  done
  assertTrue "[ -z $PILL ]"
  assertTrue "[ -z $DATA_PATH ]"
  assertFalse "[ -e commands_log ]"
  . placebo
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

. shunit2
