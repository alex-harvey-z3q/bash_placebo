if [ -z $DATA_PATH ]; then
  echo "Expected variable DATA_PATH to be set"
  return 1
fi

mkdir -p $DATA_PATH

record() {
  local f=$1
  local com=$2
  local sub=$3

  shift ; shift ; shift

  if [ -e $f ]; then
    awk '/esac/{exit}{print}' $f > $f.bak
    mv $f.bak $f
  else
    echo 'case "aws $*" in' > $f
  fi

  echo '"aws $*")'     >> $f
  echo "  cat <<'EOF'" >> $f

  command aws $com $sub $* | tee -a $f

  echo 'EOF'           >> $f
  echo '  ;;'          >> $f
  echo 'esac'          >> $f
}

aws() {
  com=$1 ; sub=$2 ; shift ; shift

  var_name=$(echo "$com$sub" | sed -e 's/-//g')
  eval "(( ${var_name}++ ))"
  eval "local c=\$${var_name}"

  data_file_name=$DATA_PATH/${com}.${sub}_${c}

  case "$PILL" in
    "playback")
      source $data_file_name $com $sub $*
      ;;
    "record")
      record $data_file_name $com $sub $*
      ;;
    *)
      echo "PILL must be set to playback or \
record but is set to '$PILL'"
      ;;
  esac
}
