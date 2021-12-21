pipeline {
	agent {
		docker {
			image 'dyalogci/node:lts'
		}
	}
	stages {
		stage ('GitHub Upload Draft Release') {
			steps {
				withCredentials([string(credentialsId: '250bdc45-ee69-451a-8783-30701df16935', variable: 'GHTOKEN')]) {
					sh './CI/GH-Release.sh'
				}
			}
		}
	}
}
