#!/bin/bash
if [[ $(curl --max-time 1 -s http://169.254.169.254 >/dev/null 2>&1) ]]; then
  # shellcheck disable=SC2006
  EC2_AVAIL_ZONE=`curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone`
  # shellcheck disable=SC2006,SC2001
  EC2_REGION="`echo \"$EC2_AVAIL_ZONE\" | sed -e 's:\([0-9][0-9]*\)[a-z]*\$:\\1:'`"
  export AWS_DEFAULT_REGION=$EC2_REGION
fi

date=$(date '+%Y-%m-%dT%H:%M:%S')
echo "[${date}] Checking for sqs messages..."
# shellcheck disable=SC2086
for message in $(aws sqs receive-message --queue-url ${SQS_URL} | jq -r .Messages); do
  if [[ -n $message ]]; then 
    # shellcheck disable=SC2086
    message_id=$(echo ${message} | jq -r .MessageId)
    date=$(date '+%Y-%m-%dT%H:%M:%S')
    echo "[${date}] processing message with id '${message_id}' ..."
    # shellcheck disable=SC2086
    receipt_handle=$(echo ${message} | jq -r .ReceiptHandle)

    # shellcheck disable=SC2086
    command=$(echo ${message} | jq -r .Body | jq -r .Message | jq -r ' .command | join(" ")')
    # do soemthing with command
    echo "${command}"
    
    # shellcheck disable=SC2181
    if [[ $? -eq 0 ]]; then
      aws sqs delete-message --queue-url "${SQS_URL}" --receipt-handle "${receipt_handle}"
    else
      date=$(date '+%Y-%m-%dT%H:%M:%S')
      echo "[${date}] Non zero exit code for docker run. Not deleting message"
    fi
  else
    date=$(date '+%Y-%m-%dT%H:%M:%S')
    echo "[${date}] No work to do"
  fi
done 
