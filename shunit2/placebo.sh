#!/usr/bin/env bash
# shellcheck disable=SC1091,SC2086

setUp() {
  . placebo
  pill_attach "command=aws" "data_path=shunit2/fixtures/aws.sh"
}

tearDown() {
  rm -f /tmp/aws
  rm -f "shunit2/fixtures/test.sh"
  rm -f expected_content
  pill_detach
}

testPlayback() {
  . placebo
  pill_attach "command=aws" "data_path=shunit2/fixtures/aws.sh"
  pill_playback
  response=$(aws autoscaling describe-auto-scaling-groups)
  assertEquals "response" "$response"
}

testRecord() {
  . placebo
  pill_attach "command=aws" "data_path=shunit2/fixtures/test.sh"
  pill_record

  OLDPATH=$PATH
  PATH=/tmp:$PATH

  echo "echo foo" > /tmp/aws ; chmod +x /tmp/aws

  command_to_run="aws ec2 run-instances --image-id foo"
  $command_to_run > /dev/null
  cat > expected_content <<EOD
case "aws \$*" in
'$command_to_run')
  cat <<'EOF'
foo
EOF
  ;;
*)
  echo "No responses for: aws \$*"
  ;;
esac
EOD

  assertEquals "" "$(diff -wu expected_content $DATA_PATH)"
  assertEquals "foo" "$(/tmp/$command_to_run)"
  assertEquals "$command_to_run" "$(pill_log)"

  PATH=$OLDPATH
}

testRecordShortCommand() {
  . placebo
  pill_attach "command=aws" "data_path=shunit2/fixtures/test.sh"
  pill_record

  OLDPATH=$PATH
  PATH=/tmp:$PATH

  echo "echo foo" > /tmp/aws ; chmod +x /tmp/aws

  command_to_run="aws help"
  $command_to_run > /dev/null
  cat > expected_content <<EOD
case "aws \$*" in
'$command_to_run')
  cat <<'EOF'
foo
EOF
  ;;
*)
  echo "No responses for: aws \$*"
  ;;
esac
EOD

  assertEquals "" "$(diff -wu expected_content $DATA_PATH)"

  PATH=$OLDPATH
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
  assertTrue "echo $response | grep -q ^Usage"
}

testDetach() {
  funcs="_usage
pill_attach
pill_playback
pill_record
pill_log
pill_detach
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

. shunit2
