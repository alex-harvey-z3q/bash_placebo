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
  pill_cleanup
  unset PILL
  unset DATA_PATH
}

testPlayback() {
  pill_playback
  response=$(aws autoscaling describe-auto-scaling-groups)
  assertEquals "response" "$response"
}

testRecord() {
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
esac
EOD

  assertEquals "" "$(diff -wu expected_content $DATA_PATH)"
  assertEquals "foo" "$(/tmp/$command_to_run)"
  assertTrue "[ -f commands_log ]"
  assertEquals "$command_to_run" "$(pill_log)"

  PATH=$OLDPATH
}

testRecordShortCommand() {
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
esac
EOD

  assertEquals "" "$(diff -wu expected_content $DATA_PATH)"

  PATH=$OLDPATH
}

testPillNotSet() {
  unset PILL
  response=$(aws ec2 run-instances)
  assertEquals \
    "PILL must be set to playback or record. Try pill_playback or pill_record" \
    "$response"
}

testDataPathNotSet() {
  pill_playback
  unset DATA_PATH
  response=$(aws ec2 run-instances)
  assertEquals \
    "DATA_PATH must be set. Try pill_attach" "$response"
}

testExecutePlacebo() {
  response=$(bash placebo)
  assertTrue "echo $response | grep -q ^Usage"
}

. shunit2
