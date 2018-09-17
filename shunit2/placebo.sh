#!/usr/bin/env bash

setUp() {
  DATA_PATH=shunit2/fixtures
}

tearDown() {
  rm -f /tmp/aws
  rm -f $DATA_PATH/ec2.run-instances.1.sh
  rm -f expected_content
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

  response_file="$DATA_PATH/ec2.run-instances.1.sh"

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
    "$(diff -wu expected_content $response_file)"

  rm -f /tmp/aws $response_file  expected_content
  PATH=$OLDPATH
}

testPillNotSet() {
  unset PILL
  response=$(. placebo)
  assertEquals \
    "PILL must be set to playback or record" "$response"
}

. shunit2
