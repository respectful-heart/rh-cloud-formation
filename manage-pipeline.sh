#!/usr/bin/env bash
aws s3 sync ./pipeline/ s3://rh-configuration-resources/pipeline --delete

sleep 2

STACKNAME="RHPipeline"
OAUTHPARAMSTRING="UsePreviousValue=true"
STACKACTION="create-change-set"
TIME="$(date +%s)"
CHANGESETNAME="RHPipeline-$TIME"

while (( "$#" )); do
  case "$1" in
    "--create")
      STACKACTION="create-stack"
      shift
      ;;
    "--GitHubOauthToken")
      OAUTHPARAMSTRING="ParameterValue=$2"
      shift 2
      ;;
  esac
done

aws cloudformation $STACKACTION \
  --stack-name $STACKNAME \
  --change-set-name $CHANGESETNAME \
  --template-url https://s3.amazonaws.com/rh-configuration-resources/pipeline/codepipeline-master.template.yml \
  --parameters ParameterKey=GitHubOauthToken,$OAUTHPARAMSTRING \
  --capabilities CAPABILITY_NAMED_IAM

if [ $STACKACTION == "create-change-set" ]; then
  echo "Waiting for change set to be ready..."
  aws cloudformation wait change-set-create-complete \
    --change-set-name $CHANGESETNAME \
    --stack-name $STACKNAME

  echo "Executing change set..."
  aws cloudformation execute-change-set \
    --change-set-name $CHANGESETNAME \
    --stack-name $STACKNAME
fi
