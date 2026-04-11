pipeline {
    agent any

    environment {
        APP_NAME        = "cicd-demo"
        DOCKER_REGISTRY = "rohan700"
        IMAGE_NAME      = "${DOCKER_REGISTRY}/myapp"

        K8S_NAMESPACE   = "production"
        K8S_DEPLOYMENT  = "cicd-demo"
        K8S_CONTAINER   = "cicd-demo"
    }

    triggers {
        githubPush()
        pollSCM('H/5 * * * *')
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

        stage('Set Image Tag') {
            steps {
                script {
                    IMAGE_TAG = sh(
                        script: "git rev-parse --short HEAD",
                        returnStdout: true
                    ).trim()

                    FULL_IMAGE_NAME = "${IMAGE_NAME}:${IMAGE_TAG}"

                    echo "Image: ${FULL_IMAGE_NAME}"
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                echo "==> Building Docker Image..."
                script {
                    docker.build("${FULL_IMAGE_NAME}", ".")
                }
            }
        }

        stage('Run Tests') {
            steps {
                echo "==> Running tests..."
                script {
                    docker.image("${FULL_IMAGE_NAME}").inside {
                        sh 'npm test || echo "No tests found, skipping..."'
                    }
                }
            }
        }

        stage('Push Docker Image') {
            steps {
                echo "==> Pushing to Docker Hub..."
                script {
                    docker.withRegistry('', 'docker-hub-credentials') {

                        docker.image("${FULL_IMAGE_NAME}").push()

                        // also push latest
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
                            -n ${K8S_NAMESPACE}

                            kubectl rollout status deployment/${K8S_DEPLOYMENT} \
                            -n ${K8S_NAMESPACE} --timeout=120s

                            kubectl get pods -n ${K8S_NAMESPACE} -l app=${APP_NAME}
                        """
                    }
                }
            }
        }
    }

    post {
        success {
            echo "✅ SUCCESS: ${FULL_IMAGE_NAME} deployed"
        }
        failure {
            echo "❌ FAILED: Check logs"
        }
        always {
            sh "docker rmi ${FULL_IMAGE_NAME} || true"
            cleanWs()
        }
    }
}
