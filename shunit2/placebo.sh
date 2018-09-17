#!/usr/bin/env bash

setUp() {
  DATA_PATH=shunit2/fixtures
}

tearDown() {
  unset PILL
  unset DATA_PATH
}

testPlayback() {
  PILL=playback
  . placebo
  aws autoscaling describe-auto-scaling-groups > /dev/null
  response2=$(aws autoscaling describe-auto-scaling-groups)
  assertEquals "response 2" "$response2"
}

testRecord() {
  PILL=record
  . placebo

  OLDPATH=$PATH
  PATH=/tmp:$PATH
  echo "echo foo" > /tmp/aws ; chmod +x /tmp/aws
  aws ec2 run-instances > /dev/null
  cat > expected_content <<'EOD'
case "aws $*" in
"aws $*")
  cat <<'EOF'
foo
EOF
  ;;
esac
EOD

  assertEquals "" \
    "$(diff -wu expected_content $DATA_PATH/ec2.run-instances.1)"

  rm -f /tmp/aws "$DATA_PATH/ec2.run-instances.1" expected_content
  PATH=$OLDPATH
}

testPillNotSet() {
  response=$(. placebo)
  assertEquals "PILL must be set to playback or record" "$response"
}

. shunit2
