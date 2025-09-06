pipeline {
    agent any
    environment {
        GIT_BRANCH = "main" // Nhanh git build
        GIT_REPO_NAME = "github.com/ltrongtinhdev/cuoikhoa"
        TELEGRAM_BOT_TOKEN = credentials('telegram-token') // Telegram bot access token
        TELEGRAM_CHAT_ID = credentials('telegram-chat-id') // Telegram bot chat id
        DOCKER_ENDPOINT = "ltrongtinh97" //Docker user Hub hoac Docker Private Resistry ENDPOINT
        DOCKER_NAME = "nginx-jenkins"
        VERSION = "1.0"
        TAG = "${GIT_BRANCH}.${VERSION}.${env.BUILD_NUMBER}"
        IMAGE_NAME = "${DOCKER_ENDPOINT}/${DOCKER_NAME}"
        SSH_USER = "admin01"
        PORT = 8900
    }
    stages {
        stage('Clone Repository') {
            steps {
                withCredentials([string(credentialsId: 'github-secret-token', variable: 'GITHUB_TOKEN')]) {
                echo 'Cloning repository...'
                sh """
                #Xoa thu muc service neu ton tai
                rm -rf service 
                git clone -b ${GIT_BRANCH} https://${GITHUB_TOKEN}@${GIT_REPO_NAME} service --depth 2
                """
                }
            }
        }
        stage('Build Docker Image') {
            steps {
                sh "printenv"
                echo 'Building Docker image...'
            dir('service') {
                sh 'docker build -t ${IMAGE_NAME}:${TAG} .'
                }
            }
        }
        stage('Push Image to Docker Hub') {
            steps {
                echo 'Push Docker image...'
                withCredentials([usernamePassword(credentialsId: 'dockerhub-credentials', passwordVariable: 'dockerHubPassword', usernameVariable: 'dockerHubUser')]) {
                    sh "docker login -u ${env.dockerHubUser} -p ${env.dockerHubPassword}"
                    sh 'docker push ${IMAGE_NAME}:${TAG}'
            }
        }
        }
        stage("Tag the version") {
             steps {
                    withCredentials([string(credentialsId: 'github-secret-token', variable: 'GITHUB_TOKEN')]) {
                    dir('service') {
                    sh """

                        git config user.email jenkins
                        git config user.name jenkins
                        git tag -a "${TAG}" -m "Jenkins build ${env.BUILD_NUMBER}"
                        #git push https://${GITHUB_TOKEN}@${GIT_REPO_NAME} ${TAG}
                        git push origin "${TAG}"
                    """
                        }
                    }
                }
        }
        stage('Deploy') {
            steps {
                script {
                    try {
                        input(
                            message: 'Bạn có muốn deploy không?',
                            ok: 'Deploy ngay!',
                            submitterParameter: 'APPROVER'
                        )
                        echo "Deploying..."
                    } catch (err) {
                        echo "Người dùng đã từ chối deploy hoặc huỷ input"
                    }
                }
            }
        }
        stage('Deploy to Servers') {
            steps {
                script {
                    // Loop through each server and deploy the Docker container
                
                        sh '''
                            #!/bin/bash
                            echo "Deploying to server"
                            ansible ${GIT_BRANCH} -i inventory.ini -m shell -a "sudo docker pull ${IMAGE_NAME}:${TAG} && sudo docker run -d --name ${DOCKER_NAME} -p ${PORT}:80 ${IMAGE_NAME}:${TAG}"
                        '''
                        
                }
            }
         }
    }
    post {
        success {
            script {
                sh """
                curl -X POST -H 'Content-Type: application/json' -d '{"chat_id": "${TELEGRAM_CHAT_ID}", "text": "✅✅✅Build ${currentBuild.result}\nJob name: ${currentBuild.fullDisplayName}\nBranch: ${GIT_BRANCH}\nJob url: ${env.BUILD_URL}", "disable_notification": false}' https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage
                """
            }
        }
        failure {
            script {
                sh """
                curl -X POST -H 'Content-Type: application/json' -d '{"chat_id": "${TELEGRAM_CHAT_ID}", "text": "❌❌❌Build ${currentBuild.result} \nJob name: ${currentBuild.fullDisplayName}\nBranch: ${GIT_BRANCH}\nJob url: ${env.BUILD_URL}", "disable_notification": false}' https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage
                """
            }
        }
    }
}
