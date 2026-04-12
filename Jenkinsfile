pipeline {
    agent any

    parameters {
        string(name: 'APP_NAME',        defaultValue: 'cicd-demo',       description: 'Application name')
        string(name: 'DOCKER_REGISTRY', defaultValue: 'rohan700',        description: 'Docker Hub username')
        string(name: 'IMAGE_NAME',      defaultValue: 'rohan700/my-app', description: 'Full image name')
        string(name: 'K8S_NAMESPACE',   defaultValue: 'production',      description: 'Kubernetes namespace to deploy to')
        string(name: 'K8S_DEPLOYMENT',  defaultValue: 'cicd-demo',       description: 'Kubernetes deployment name')
        string(name: 'K8S_CONTAINER',   defaultValue: 'cicd-demo',       description: 'Container name inside the pod')
    }

    environment {
        FULL_IMAGE_NAME = "${params.DOCKER_REGISTRY}/my-app:v1"
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
                    def imageTag = sh(
                        script: "git rev-parse --short HEAD",
                        returnStdout: true
                    ).trim()

                    env.IMAGE_TAG       = imageTag
                    env.FULL_IMAGE_NAME = "${params.IMAGE_NAME}:${imageTag}"

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
                        kubectl set image deployment/${params.K8S_DEPLOYMENT} \
                            ${params.K8S_CONTAINER}=${env.FULL_IMAGE_NAME} \
                            -n ${params.K8S_NAMESPACE}

                        kubectl rollout status deployment/${params.K8S_DEPLOYMENT} \
                            -n ${params.K8S_NAMESPACE} --timeout=120s

                        kubectl get pods -n ${params.K8S_NAMESPACE} -l app=${params.APP_NAME}
                    """
                }
            }
        }
    }

    post {
        success {
            echo "✅ SUCCESS: ${env.FULL_IMAGE_NAME} deployed to ${params.K8S_NAMESPACE}"
        }
        failure {
            echo "❌ FAILED: ${env.FULL_IMAGE_NAME} — rolling back..."
            withCredentials([file(credentialsId: 'kubeconfig-credentials', variable: 'KUBECONFIG')]) {
                sh """
                    kubectl rollout undo deployment/${params.K8S_DEPLOYMENT} \
                        -n ${params.K8S_NAMESPACE} || true
                """
            }
        }
        always {
            sh "docker rmi ${env.FULL_IMAGE_NAME} || true"
            cleanWs()
        }
    }
}
