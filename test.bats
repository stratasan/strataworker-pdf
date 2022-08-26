#!/usr/bin/env bats

function setup() {
  export HOSTNAME=$HOSTNAME
  export AWS_LAMBDA_EVENT_BODY="{\"url\": \"file:///var/task/resources/test/fixtures/helloworld.html\", \"bucket\": \"somebucket\", \"filename\": \"foo.pdf\", \"force\": \"True\"}"
  docker-compose up -d localstack
  sleep 5
  aws s3 mb s3://somebucket --endpoint http://localhost:4566
}

function teardown() {
  unset AWS_LAMBDA_EVENT_BODY
  docker-compose down
}

@test "Translates an HTML file to PDF in s3" {
  docker-compose run mocklambda
  files_in_s3=$(aws s3 ls s3://somebucket/ --endpoint http://localhost:4566 --recursive | wc -l)
  [[ $files_in_s3 -ge 1 ]]
  temp_filename=$(mktemp)
  aws s3 cp s3://somebucket/foo.pdf ${temp_filename} --endpoint http://localhost:4566
  diff <(cat resources/test/fixtures/helloworld.pdfinfo | grep -vE 'CreationDate|UserProperties|Suspects|JavaScript') <(pdfinfo ${temp_filename} | grep -vE 'CreationDate|UserProperties|Suspects|JavaScript')
}
