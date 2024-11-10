pipeline {
    agent any

    environment {
        KUBECONFIG = '/var/lib/jenkins/.kube/config'
        DOCKER_IMAGE = 'mounabnz/hello-spring:latest'
        DOCKER_CREDENTIALS_ID = credentials('DOCKER_CRED_ID') // Securely retrieved from Jenkins credentials
        NAGIOS_URL = 'http://localhost/nagios/cgi-bin/statusjson.cgi'
        NAGIOS_USER = credentials('NAGIOS_USER_ID')  // Securely retrieved from Jenkins credentials
        NAGIOS_PASS = credentials('NAGIOS_PASS_ID')  // Securely retrieved from Jenkins credentials
    }

    stages {
        stage("Build Docker Image") {
            steps {
                sh """
                    docker build -t $DOCKER_IMAGE .
                """
            }
        }

        stage("Push Docker Image") {
            steps {
                script {
                    docker.withRegistry('https://index.docker.io/v1/', "$DOCKER_CREDENTIALS_ID") {
                        sh "docker push $DOCKER_IMAGE"
                    }
                }
            }
        }

        stage("Deploy to Kubernetes") {
            steps {
                sh """
                    kubectl apply -f k8s/deployment.yaml --kubeconfig=$KUBECONFIG
                    kubectl set image deployment/my-deployment my-container=$DOCKER_IMAGE --record --kubeconfig=$KUBECONFIG
                """
            }
        }

        stage("Nagios Monitoring Check") {
            steps {
                sh """
                    curl -s -u $NAGIOS_USER:$NAGIOS_PASS "$NAGIOS_URL?query=service&hostname=localhost&servicedescription=HTTP"
                """
            }
        }
    }
}
