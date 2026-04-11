pipeline {
    agent any

    environment {
        APP_NAME        = "cicd-demo"
        DOCKER_REGISTRY = "YOUR_DOCKERHUB_USERNAME"
        IMAGE_TAG        = "${APP_NAME}:${env.GIT_COMMIT?.take(7) ?: 'latest'}"
        FULL_IMAGE_NAME  = "${DOCKER_REGISTRY}/${IMAGE_TAG}"
        K8S_NAMESPACE    = "production"
        K8S_DEPLOYMENT   = "cicd-demo-deployment"
        K8S_CONTAINER    = "cicd-demo-container"
    }

    triggers {
        githubPush()         // Triggers instantly on git push via webhook
        pollSCM('H/5 * * * *') // Fallback polling every 5 min (in case webhook fails)
    }

    options {
        buildDiscarder(logRotator(numToKeepStr: '10'))
        timeout(time: 30, unit: 'MINUTES')
        timestamps()
        disableConcurrentBuilds()
    }

    stages {
        stage('Checkout') {
            steps {
                echo "==> Checking out code..."
                checkout scm
                sh 'git log -1 --oneline'
            }
        }

        stage('Build Docker Image') {
            steps {
                echo "==> Building: ${FULL_IMAGE_NAME}"
                script {
                    docker.build("${FULL_IMAGE_NAME}", "--no-cache .")
                }
            }
        }

        stage('Run Tests') {
            steps {
                echo "==> Running tests..."
                script {
                    docker.image("${FULL_IMAGE_NAME}").inside {
                        sh 'npm test'
                    }
                }
            }
        }

        stage('Push Docker Image') {
            steps {
                echo "==> Pushing to Docker Hub..."
                script {
                    docker.withRegistry('https://index.docker.io/v1/', 'docker-hub-credentials') {
                        docker.image("${FULL_IMAGE_NAME}").push()
                        docker.image("${FULL_IMAGE_NAME}").push('latest')
                    }
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                echo "==> Deploying to Kubernetes..."
                withCredentials([file(credentialsId: 'kubeconfig-credentials', variable: 'KUBECONFIG')]) {
                    script {
                        sh """
                            kubectl set image deployment/${K8S_DEPLOYMENT} \
                                ${K8S_CONTAINER}=${FULL_IMAGE_NAME} \
                                --namespace=${K8S_NAMESPACE}

                            kubectl rollout status deployment/${K8S_DEPLOYMENT} \
                                --namespace=${K8S_NAMESPACE} \
                                --timeout=120s

                            kubectl get pods --namespace=${K8S_NAMESPACE} -l app=${APP_NAME} --output=wide
                        """
                    }
                }
            }
        }
    }

    post {
        success {
            echo "==> BUILD SUCCESSFUL: ${FULL_IMAGE_NAME} deployed to ${K8S_NAMESPACE}"
        }
        failure {
            echo "==> BUILD FAILED - check console output above"
            // Optional: add email/Slack notification here
            // mail to: 'you@example.com', subject: "FAILED: ${env.JOB_NAME}", body: "Check: ${env.BUILD_URL}"
        }
        always {
            sh "docker rmi ${FULL_IMAGE_NAME} || true"
            cleanWs()
        }
    }
}
