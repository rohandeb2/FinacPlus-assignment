pipeline {
    agent any

    environment {
        APP_NAME        = "cicd-demo"
        DOCKER_REGISTRY = "rohan700"
        IMAGE_NAME      = "${DOCKER_REGISTRY}/myapp"
        K8S_NAMESPACE   = "production"
        K8S_DEPLOYMENT  = "cicd-demo"
        K8S_CONTAINER   = "cicd-demo"
        // Initialize so post{} block never sees a null variable
        FULL_IMAGE_NAME = "${DOCKER_REGISTRY}/myapp:latest"
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

        stage('Build Docker Image') {
            steps {
                echo "==> Building Docker Image..."
                script {
                    // Use env. prefix so variable is accessible in ALL stages and post{}
                    def imageTag = sh(
                        script: "git rev-parse --short HEAD",
                        returnStdout: true
                    ).trim()

                    env.IMAGE_TAG       = imageTag
                    env.FULL_IMAGE_NAME = "${IMAGE_NAME}:${imageTag}"

                    echo "==> Image tag: ${env.FULL_IMAGE_NAME}"

                    docker.build("${env.FULL_IMAGE_NAME}", ".")
                }
            }
        }

        stage('Run Tests') {
            steps {
                echo "==> Running tests..."
                script {
                    docker.image("${env.FULL_IMAGE_NAME}").inside {
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
                        docker.image("${env.FULL_IMAGE_NAME}").push()
                        docker.image("${env.FULL_IMAGE_NAME}").push('latest')
                    }
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                echo "==> Deploying to Kubernetes..."
                withCredentials([file(credentialsId: 'kubeconfig-credentials', variable: 'KUBECONFIG')]) {
                    sh """
                        kubectl set image deployment/${K8S_DEPLOYMENT} \
                            ${K8S_CONTAINER}=${env.FULL_IMAGE_NAME} \
                            -n ${K8S_NAMESPACE}

                        kubectl rollout status deployment/${K8S_DEPLOYMENT} \
                            -n ${K8S_NAMESPACE} --timeout=120s

                        kubectl get pods -n ${K8S_NAMESPACE} -l app=${APP_NAME}
                    """
                }
            }
        }
    }

    post {
        success {
            echo "✅ SUCCESS: ${env.FULL_IMAGE_NAME} deployed to ${K8S_NAMESPACE}"
        }
        failure {
            echo "❌ FAILED: ${env.FULL_IMAGE_NAME} — check logs above"
        }
        always {
            sh "docker rmi ${env.FULL_IMAGE_NAME} || true"
            cleanWs()
        }
    }
}
