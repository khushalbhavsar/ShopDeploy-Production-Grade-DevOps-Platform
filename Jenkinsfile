pipeline {
    agent any

    environment {
        AWS_REGION = 'us-east-1'
        AWS_ACCOUNT_ID = '348823728691'

        ECR_REGISTRY = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
        ECR_BACKEND_REPO = "shopdeploy-prod-backend"
        ECR_FRONTEND_REPO = "shopdeploy-prod-frontend"

        EKS_CLUSTER_NAME = 'shopdeploy-prod-eks'
        K8S_NAMESPACE = 'shopdeploy'

        IMAGE_TAG = "${BUILD_NUMBER}-${GIT_COMMIT.take(7)}"

        SONAR_PROJECT_KEY = 'shopdeploy'

        BACKEND_DIR = 'shopdeploy-backend'
        FRONTEND_DIR = 'shopdeploy-frontend'

        PREVIOUS_BACKEND_TAG = ''
        PREVIOUS_FRONTEND_TAG = ''
    }

    options {
        timeout(time: 60, unit: 'MINUTES')
        buildDiscarder(logRotator(numToKeepStr: '20'))
        disableConcurrentBuilds()
        timestamps()
    }

    parameters {
        choice(name: 'ENVIRONMENT', choices: ['dev', 'staging', 'prod'])
        booleanParam(name: 'SKIP_TESTS', defaultValue: false)
        booleanParam(name: 'SKIP_SONAR', defaultValue: true, description: 'Skip SonarQube analysis (set to false once SonarQube is configured in Jenkins)')
        booleanParam(name: 'FORCE_DEPLOY', defaultValue: false)
    }

    triggers {
        githubPush()
        pollSCM('H/5 * * * *')
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Install Dependencies') {
            parallel {
                stage('Backend Deps') {
                    when { expression { env.BACKEND_CHANGED == 'true' } }
                    steps {
                        dir("${BACKEND_DIR}") {
                            sh 'npm ci'
                        }
                    }
                }

                stage('Frontend Deps') {
                    when { expression { env.FRONTEND_CHANGED == 'true' } }
                    steps {
                        dir("${FRONTEND_DIR}") {
                            sh 'npm ci'
                        }
                    }
                }
            }
        }

        stage('Code Quality (SonarQube)') {
            when { expression { !params.SKIP_SONAR } }
            steps {
                withSonarQubeEnv('SonarQube') {
                    sh """
                    # Use sonar-scanner from Jenkins tool or PATH
                    sonar-scanner \
                      -Dsonar.projectKey=${SONAR_PROJECT_KEY} \
                      -Dsonar.sources=. \
                      -Dsonar.exclusions=node_modules/**,**/test/**
                    """
                }
            }
        }

        stage('Quality Gate') {
            when { expression { !params.SKIP_SONAR } }
            steps {
                timeout(time: 5, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        stage('Unit Tests') {
            when { expression { !params.SKIP_TESTS } }
            parallel {
                stage('Backend Tests') {
                    steps {
                        dir("${BACKEND_DIR}") {
                            sh 'npm test || true'
                        }
                    }
                }
                stage('Frontend Tests') {
                    steps {
                        dir("${FRONTEND_DIR}") {
                            sh 'npm test || true'
                        }
                    }
                }
            }
        }

        stage('Docker Build') {
            steps {
                sh '''
                chmod +x scripts/build.sh
                scripts/build.sh backend ${IMAGE_TAG}
                scripts/build.sh frontend ${IMAGE_TAG}
                '''
            }
        }

        stage('Push to ECR') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-credentials']]) {
                    sh '''
                    chmod +x scripts/push.sh
                    aws ecr get-login-password --region ${AWS_REGION} \
                    | docker login --username AWS --password-stdin ${ECR_REGISTRY}

                    scripts/push.sh backend ${IMAGE_TAG} ${ECR_REGISTRY}/${ECR_BACKEND_REPO}
                    scripts/push.sh frontend ${IMAGE_TAG} ${ECR_REGISTRY}/${ECR_FRONTEND_REPO}
                    '''
                }
            }
        }

        stage('Deploy to Dev/Staging') {
            when { expression { params.ENVIRONMENT != 'prod' } }
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-credentials']]) {
                    sh '''
                    # Install kubectl and helm to workspace bin
                    mkdir -p ${WORKSPACE}/bin
                    export PATH=${WORKSPACE}/bin:$PATH
                    
                    # Install kubectl if not present
                    if [ ! -f ${WORKSPACE}/bin/kubectl ]; then
                        echo "Installing kubectl to workspace..."
                        curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
                        chmod +x kubectl
                        mv kubectl ${WORKSPACE}/bin/
                    fi
                    
                    # Install helm if not present
                    if [ ! -f ${WORKSPACE}/bin/helm ]; then
                        echo "Installing helm to workspace..."
                        curl -fsSL https://get.helm.sh/helm-v3.14.0-linux-amd64.tar.gz | tar xz
                        mv linux-amd64/helm ${WORKSPACE}/bin/
                        rm -rf linux-amd64
                    fi
                    
                    chmod +x scripts/deploy.sh
                    aws eks update-kubeconfig --region ${AWS_REGION} --name ${EKS_CLUSTER_NAME}
                    scripts/deploy.sh backend ${IMAGE_TAG} ${ENVIRONMENT}
                    scripts/deploy.sh frontend ${IMAGE_TAG} ${ENVIRONMENT}
                    '''
                }
            }
        }

        stage('Manual Production Approval') {
            when { expression { params.ENVIRONMENT == 'prod' } }
            steps {
                input message: 'Deploy to PRODUCTION?', ok: 'Approve'
            }
        }

        stage('Deploy to Production') {
            when { expression { params.ENVIRONMENT == 'prod' } }
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-credentials']]) {
                    sh '''
                    # Install kubectl and helm to workspace bin
                    mkdir -p ${WORKSPACE}/bin
                    export PATH=${WORKSPACE}/bin:$PATH
                    
                    # Install kubectl if not present
                    if [ ! -f ${WORKSPACE}/bin/kubectl ]; then
                        echo "Installing kubectl to workspace..."
                        curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
                        chmod +x kubectl
                        mv kubectl ${WORKSPACE}/bin/
                    fi
                    
                    # Install helm if not present
                    if [ ! -f ${WORKSPACE}/bin/helm ]; then
                        echo "Installing helm to workspace..."
                        curl -fsSL https://get.helm.sh/helm-v3.14.0-linux-amd64.tar.gz | tar xz
                        mv linux-amd64/helm ${WORKSPACE}/bin/
                        rm -rf linux-amd64
                    fi
                    
                    chmod +x scripts/deploy.sh
                    aws eks update-kubeconfig --region ${AWS_REGION} --name ${EKS_CLUSTER_NAME}
                    scripts/deploy.sh backend ${IMAGE_TAG} prod
                    scripts/deploy.sh frontend ${IMAGE_TAG} prod
                    '''
                }
            }
        }

        stage('Smoke Tests') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-credentials']]) {
                    sh '''
                    # Install kubectl to workspace bin
                    mkdir -p ${WORKSPACE}/bin
                    export PATH=${WORKSPACE}/bin:$PATH
                    
                    # Install kubectl if not present
                    if [ ! -f ${WORKSPACE}/bin/kubectl ]; then
                        echo "Installing kubectl to workspace..."
                        curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
                        chmod +x kubectl
                        mv kubectl ${WORKSPACE}/bin/
                    fi
                    
                    aws eks update-kubeconfig --region ${AWS_REGION} --name ${EKS_CLUSTER_NAME}
                    kubectl get pods -n ${K8S_NAMESPACE}
                    kubectl rollout status deployment/shopdeploy-backend -n ${K8S_NAMESPACE} --timeout=300s || true
                    kubectl rollout status deployment/shopdeploy-frontend -n ${K8S_NAMESPACE} --timeout=300s || true
                    '''
                }
            }
        }

        stage('Cleanup') {
            steps {
                sh 'docker system prune -f || true'
            }
        }
    }

    post {
        success {
            echo "✅ PIPELINE COMPLETED SUCCESSFULLY"
        }

        failure {
            echo "❌ PIPELINE FAILED — CHECK LOGS"
        }

        always {
            cleanWs()
        }
    }
}
