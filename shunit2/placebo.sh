#!/usr/bin/env bash

setUp() {
  . placebo
  pill_attach /usr/local/bin/aws "data_path=shunit2/fixtures/aws.sh"
}

tearDown() {
  rm -f /tmp/aws
  rm -f "shunit2/fixtures/test.sh"
  rm -f expected_content
  rm -f commands_log
  unset PILL
  unset DATA_PATH
}

testPlayback() {
  pill_playback
  response=$(aws autoscaling describe-auto-scaling-groups)
  assertEquals "response" "$response"
}

testRecord() {
  pill_attach /usr/local/bin/aws "data_path=shunit2/fixtures/test.sh" -spy
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
  assertEquals "$SPY" "true"
  assertTrue "[ -f commands_log ]"
  assertEquals "$command_to_run" "$(<commands_log)"

  PATH=$OLDPATH
}

testPillNotSet() {
  unset PILL
  response=$(aws ec2 run-instances)
  assertEquals \
    "PILL must be set to playback or record" "$response"
}

testDataPathNotSet() {
  pill_playback
  unset DATA_PATH
  response=$(aws ec2 run-instances)
  assertEquals \
    "DATA_PATH must be set" "$response"
}

. shunit2
