case "aws $*" in
'aws autoscaling describe-auto-scaling-groups')
  cat <<'EOF'
response
EOF
  ;;
*)
  echo "No responses for: aws $*" | tee -a unknown_commands
  ;;
esac
