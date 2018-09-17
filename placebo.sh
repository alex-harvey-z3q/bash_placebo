if [ -z $DATA_PATH ]; then
  echo "Expected variable DATA_PATH to be set"
  return 1
fi

mkdir -p $DATA_PATH

aws() {
  com=$1 ; sub=$2 ; shift ; shift
  var_name=$(echo "$com$sub" | sed -e 's/-//g')
  eval "(( ${var_name}++ ))"
  eval "local c=\$${var_name}"
  source $DATA_PATH/${com}.${sub}_${c} $com $sub $*
}
