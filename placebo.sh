if ! echo $PILL | grep -q "(playback|record)" ; then
  echo "PILL must be set to playback or record"
  return 1
fi

if [ -z $DATA_PATH ] ; then
  echo "DATA_PATH must be set"
  return 1
fi

mkdir -p $DATA_PATH

create_new() {
  local f=$1
  echo 'case "aws $*" in' > $f
}

update_existing() {
  local f=$1
  awk '/^esac/{exit}{print}' $f > $f.bak
  mv $f.bak $f
}

record() {
  local f=$1
  local com=$2
  local sub=$3
  shift ; shift ; shift

  if [ -e $f ] ; then
    update_existing $f
  else
    create_new $f
  fi

  cat >> $f <<'EOD'
"aws $*")
  cat <<'EOF'
EOD

  command aws $com $sub $* | \
    tee -a $f

  cat >> $f <<'EOD'
EOF
  ;;
esac
EOD
}

aws() {
  local com=$1
  local sub=$2
  shift ; shift

  var_name=$(echo "$com$sub" | sed -e 's/-//g')

  eval "(( ${var_name}++ ))"
  eval 'local counter=$'"$var_name"

  data_file=${DATA_PATH}/${com}.${sub}.${counter}

  case "$PILL" in
  "playback")
    source $data_file $com $sub $*
    ;;
  "record")
    record $data_file $com $sub $*
    ;;
  esac
}
