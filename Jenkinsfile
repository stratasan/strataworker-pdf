#!/usr/bin/env groovy

node('ec2') {
  stage('Checkout') {
    checkout scm
  }
  timestamps {
    try {
      stage('test') {
        docker.image('python:3.6').inside("-u 0") {
          sh '''
            pip install -U pip
            pip install pipenv
            pipenv install --dev --system
            make test
          '''
        }
      }
      currentBuild.result = 'SUCCESS'

    } catch (err) {
      currentBuild.result = 'FAILURE'
      throw err
    } finally {
      node('master') {
        logstashSend failBuild: false
      }
    }
  }
}
