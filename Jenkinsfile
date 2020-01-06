#!/usr/bin/env groovy
ansiColor('xterm') {
  timestamps {
    node('deploy') {
      stage('Clean') {
        sh 'sudo chown $(whoami) . -R' // docker runs can turn permissions into root on some runs
        deleteDir()
        cleanWs()
      }
    
      stage('Checkout') {
        checkout scm
      }
    
      stage('Test') {
        try {


          def localstackEnvVarStr = '-e SERVICES=lambda,s3 -e DEBUG=1 -e LAMBDA_EXECUTOR=docker -e DOCKER_HOST=unix:///var/run/docker.sock'

          docker.image('localstack/localstack:latest').withRun(localstackEnvVarStr) { localstack ->
            docker.image('alpine:latest').inside("-u 0 --link ${localstack.id}:localstack") {
              sh '''
                echo http://dl-cdn.alpinelinux.org/alpine/edge/testing >>/etc/apk/repositories
                apk add -U aws-cli
                aws s3 mb s3://somebucket --endpoint http://localstack:4572
              '''
            }

            def awsLambdaEventBody = "\"{\\\"url\\\": \\\"file:///var/task/resources/test/fixtures/helloworld.html\\\", \\\"bucket\\\": \\\"somebucket\\\", \\\"filename\\\": \\\"foo.pdf\\\", \\\"force\\\": \\\"True\\\"}\""
            def lambciEnvVarStr = "-e ENDPOINT_URL=http://localstack:4572 -e AWS_LAMBDA_EVENT_BODY=${awsLambdaEventBody} -e ENABLE_SENTRY=False"
            def current

            docker.image('lambci/lambda:python3.6').inside("-u 0 -w /var/task -v ${WORKSPACE}:/var/task --link ${localstack.id}:localstack ${lambciEnvVarStr}") {
              sh '''
                easy_install-3.6 virtualenv
                virtualenv dist
                . dist/bin/activate
                pip install -r requirements.txt -t dist >/dev/null
                /var/lang/bin/python3.6 /var/runtime/awslambda/bootstrap.py
              ''' 
            }

            docker.image('alpine:latest').inside("-u 0 --link ${localstack.id}:localstack") {
              sh '''
                echo http://dl-cdn.alpinelinux.org/alpine/edge/testing >>/etc/apk/repositories
                apk add -U aws-cli bash poppler-utils
              '''

              sh '''#!/bin/bash -ex
                files_in_s3=$(aws s3 ls s3://somebucket/ --endpoint http://localstack:4572 --recursive | wc -l)
                [[ $files_in_s3 -ge 1 ]]
                aws s3 cp s3://somebucket/foo.pdf . --endpoint http://localstack:4572
                diff resources/test/fixtures/helloworld.pdfinfo <(pdfinfo foo.pdf | grep -v CreationDate)
              '''
            }
          }

          currentBuild.result = 'SUCCESS'
    
        } catch (err) {
          currentBuild.result = 'FAILURE'
          throw err
        } finally {
          node('master') {
          }
        }
      }
    }
  }
}
