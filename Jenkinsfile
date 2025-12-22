//==============================================================================
// ShopDeploy - Declarative Jenkins Pipeline
// Production-Grade CI/CD Pipeline for E-Commerce Application
//==============================================================================

pipeline {
    agent any

    //--------------------------------------------------------------------------
    // Environment Variables
    //--------------------------------------------------------------------------
    environment {
        // AWS Configuration
        AWS_REGION = 'us-east-1'
        AWS_ACCOUNT_ID = 348823728691 // AWS Account ID stored in Jenkins credentials
        
        // ECR Configuration
        ECR_REGISTRY = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
        ECR_BACKEND_REPO = "shopdeploy-prod-backend"
        ECR_FRONTEND_REPO = "shopdeploy-prod-frontend"
        
        // EKS Configuration
        EKS_CLUSTER_NAME = 'shopdeploy-prod-eks'
        K8S_NAMESPACE = 'shopdeploy'
        
        // Docker Image Tags
        IMAGE_TAG = "${BUILD_NUMBER}-${GIT_COMMIT.take(7)}"
        LATEST_TAG = 'latest'
        
        // Helm Configuration
        HELM_RELEASE_BACKEND = 'shopdeploy-backend'
        HELM_RELEASE_FRONTEND = 'shopdeploy-frontend'
        
        // Application Paths
        BACKEND_DIR = 'shopdeploy-backend'
        FRONTEND_DIR = 'shopdeploy-frontend'
        
        // Email Notification
        EMAIL_RECIPIENTS = 'devops-team@yourcompany.com'
    }

    //--------------------------------------------------------------------------
    // Pipeline Options
    //--------------------------------------------------------------------------
    options {
        timeout(time: 60, unit: 'MINUTES')
        buildDiscarder(logRotator(numToKeepStr: '20'))
        disableConcurrentBuilds()
        timestamps()
        ansiColor('xterm')
    }

    //--------------------------------------------------------------------------
    // Pipeline Parameters
    //--------------------------------------------------------------------------
    parameters {
        choice(
            name: 'ENVIRONMENT',
            choices: ['dev', 'staging', 'prod'],
            description: 'Target deployment environment'
        )
        booleanParam(
            name: 'SKIP_TESTS',
            defaultValue: false,
            description: 'Skip test stage (not recommended for production)'
        )
        booleanParam(
            name: 'FORCE_DEPLOY',
            defaultValue: false,
            description: 'Force deployment even if no changes detected'
        )
        string(
            name: 'BACKEND_VERSION',
            defaultValue: '',
            description: 'Specific backend version to deploy (leave empty for latest build)'
        )
        string(
            name: 'FRONTEND_VERSION',
            defaultValue: '',
            description: 'Specific frontend version to deploy (leave empty for latest build)'
        )
    }

    //--------------------------------------------------------------------------
    // Pipeline Triggers
    //--------------------------------------------------------------------------
    triggers {
        // GitHub webhook trigger
        githubPush()
        // Poll SCM as fallback (every 5 minutes)
        pollSCM('H/5 * * * *')
    }

    //--------------------------------------------------------------------------
    // Pipeline Stages
    //--------------------------------------------------------------------------
    stages {
        //----------------------------------------------------------------------
        // Stage 1: Checkout Source Code
        //----------------------------------------------------------------------
        stage('Checkout') {
            steps {
                script {
                    echo "=========================================="
                    echo "Stage: Checkout Source Code"
                    echo "=========================================="
                }
                checkout scm
                
                script {
                    // Get commit info for notifications
                    env.GIT_COMMIT_MSG = sh(
                        script: 'git log -1 --pretty=%B',
                        returnStdout: true
                    ).trim()
                    env.GIT_AUTHOR = sh(
                        script: 'git log -1 --pretty=%an',
                        returnStdout: true
                    ).trim()
                }
            }
        }

        //----------------------------------------------------------------------
        // Stage 2: Detect Changes
        //----------------------------------------------------------------------
        stage('Detect Changes') {
            steps {
                script {
                    echo "=========================================="
                    echo "Stage: Detect Code Changes"
                    echo "=========================================="
                    
                    // Detect which components have changed
                    def changes = sh(
                        script: 'git diff --name-only HEAD~1 HEAD',
                        returnStdout: true
                    ).trim()
                    
                    env.BACKEND_CHANGED = changes.contains('shopdeploy-backend/') || params.FORCE_DEPLOY
                    env.FRONTEND_CHANGED = changes.contains('shopdeploy-frontend/') || params.FORCE_DEPLOY
                    env.INFRA_CHANGED = changes.contains('terraform/') || changes.contains('k8s/') || changes.contains('helm/')
                    
                    echo "Backend changed: ${env.BACKEND_CHANGED}"
                    echo "Frontend changed: ${env.FRONTEND_CHANGED}"
                    echo "Infrastructure changed: ${env.INFRA_CHANGED}"
                }
            }
        }

        //----------------------------------------------------------------------
        // Stage 3: Install Dependencies
        //----------------------------------------------------------------------
        stage('Install Dependencies') {
            parallel {
                stage('Backend Dependencies') {
                    when {
                        expression { env.BACKEND_CHANGED == 'true' }
                    }
                    steps {
                        dir("${BACKEND_DIR}") {
                            sh 'npm ci --production=false'
                        }
                    }
                }
                stage('Frontend Dependencies') {
                    when {
                        expression { env.FRONTEND_CHANGED == 'true' }
                    }
                    steps {
                        dir("${FRONTEND_DIR}") {
                            sh 'npm ci'
                        }
                    }
                }
            }
        }

        //----------------------------------------------------------------------
        // Stage 4: Code Quality & Security Scan
        //----------------------------------------------------------------------
        stage('Code Quality') {
            when {
                expression { !params.SKIP_TESTS }
            }
            parallel {
                stage('Backend Lint') {
                    when {
                        expression { env.BACKEND_CHANGED == 'true' }
                    }
                    steps {
                        dir("${BACKEND_DIR}") {
                            sh 'npm run lint || true'
                        }
                    }
                }
                stage('Frontend Lint') {
                    when {
                        expression { env.FRONTEND_CHANGED == 'true' }
                    }
                    steps {
                        dir("${FRONTEND_DIR}") {
                            sh 'npm run lint || true'
                        }
                    }
                }
                stage('Security Scan') {
                    steps {
                        sh '''
                            # Run npm audit for security vulnerabilities
                            cd ${BACKEND_DIR} && npm audit --audit-level=high || true
                            cd ../${FRONTEND_DIR} && npm audit --audit-level=high || true
                        '''
                    }
                }
            }
        }

        //----------------------------------------------------------------------
        // Stage 5: Run Tests
        //----------------------------------------------------------------------
        stage('Test') {
            when {
                expression { !params.SKIP_TESTS }
            }
            parallel {
                stage('Backend Tests') {
                    when {
                        expression { env.BACKEND_CHANGED == 'true' }
                    }
                    steps {
                        dir("${BACKEND_DIR}") {
                            sh '''
                                chmod +x ../scripts/test.sh
                                ../scripts/test.sh backend
                            '''
                        }
                    }
                    post {
                        always {
                            publishHTML([
                                allowMissing: true,
                                alwaysLinkToLastBuild: true,
                                keepAll: true,
                                reportDir: "${BACKEND_DIR}/coverage",
                                reportFiles: 'index.html',
                                reportName: 'Backend Coverage Report'
                            ])
                        }
                    }
                }
                stage('Frontend Tests') {
                    when {
                        expression { env.FRONTEND_CHANGED == 'true' }
                    }
                    steps {
                        dir("${FRONTEND_DIR}") {
                            sh '''
                                chmod +x ../scripts/test.sh
                                ../scripts/test.sh frontend
                            '''
                        }
                    }
                }
            }
        }

        //----------------------------------------------------------------------
        // Stage 6: Build Docker Images
        //----------------------------------------------------------------------
        stage('Build Docker Images') {
            parallel {
                stage('Build Backend Image') {
                    when {
                        expression { env.BACKEND_CHANGED == 'true' }
                    }
                    steps {
                        script {
                            echo "Building Backend Docker Image..."
                            sh """
                                chmod +x scripts/build.sh
                                scripts/build.sh backend ${IMAGE_TAG}
                            """
                        }
                    }
                }
                stage('Build Frontend Image') {
                    when {
                        expression { env.FRONTEND_CHANGED == 'true' }
                    }
                    steps {
                        script {
                            echo "Building Frontend Docker Image..."
                            sh """
                                chmod +x scripts/build.sh
                                scripts/build.sh frontend ${IMAGE_TAG}
                            """
                        }
                    }
                }
            }
        }

        //----------------------------------------------------------------------
        // Stage 7: Push Images to ECR
        //----------------------------------------------------------------------
        stage('Push to ECR') {
            steps {
                script {
                    echo "=========================================="
                    echo "Stage: Push Docker Images to ECR"
                    echo "=========================================="
                    
                    withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', 
                                      credentialsId: 'aws-credentials']]) {
                        sh """
                            chmod +x scripts/push.sh
                            
                            # Login to ECR
                            aws ecr get-login-password --region ${AWS_REGION} | \
                                docker login --username AWS --password-stdin ${ECR_REGISTRY}
                        """
                        
                        // Push Backend if changed
                        if (env.BACKEND_CHANGED == 'true') {
                            sh """
                                scripts/push.sh backend ${IMAGE_TAG} ${ECR_REGISTRY}/${ECR_BACKEND_REPO}
                            """
                        }
                        
                        // Push Frontend if changed
                        if (env.FRONTEND_CHANGED == 'true') {
                            sh """
                                scripts/push.sh frontend ${IMAGE_TAG} ${ECR_REGISTRY}/${ECR_FRONTEND_REPO}
                            """
                        }
                    }
                }
            }
        }

        //----------------------------------------------------------------------
        // Stage 8: Deploy to Kubernetes using Helm
        //----------------------------------------------------------------------
        stage('Deploy to EKS') {
            when {
                expression { params.ENVIRONMENT != 'prod' || currentBuild.result == null }
            }
            steps {
                script {
                    echo "=========================================="
                    echo "Stage: Deploy to ${params.ENVIRONMENT} Environment"
                    echo "=========================================="
                    
                    withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', 
                                      credentialsId: 'aws-credentials']]) {
                        sh """
                            # Configure kubectl for EKS
                            aws eks update-kubeconfig --region ${AWS_REGION} --name ${EKS_CLUSTER_NAME}
                            
                            chmod +x scripts/deploy.sh
                        """
                        
                        // Deploy Backend
                        if (env.BACKEND_CHANGED == 'true' || params.BACKEND_VERSION) {
                            def backendTag = params.BACKEND_VERSION ?: IMAGE_TAG
                            sh """
                                scripts/deploy.sh backend ${backendTag} ${params.ENVIRONMENT}
                            """
                        }
                        
                        // Deploy Frontend
                        if (env.FRONTEND_CHANGED == 'true' || params.FRONTEND_VERSION) {
                            def frontendTag = params.FRONTEND_VERSION ?: IMAGE_TAG
                            sh """
                                scripts/deploy.sh frontend ${frontendTag} ${params.ENVIRONMENT}
                            """
                        }
                    }
                }
            }
        }

        //----------------------------------------------------------------------
        // Stage 9: Production Approval Gate
        //----------------------------------------------------------------------
        stage('Production Approval') {
            when {
                expression { params.ENVIRONMENT == 'prod' }
            }
            steps {
                script {
                    echo "=========================================="
                    echo "Stage: Production Deployment Approval"
                    echo "=========================================="
                    
                    // Send email notification for approval
                    emailext(
                        to: env.EMAIL_RECIPIENTS,
                        subject: "[ACTION REQUIRED] Production Deployment Approval - ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                        body: """
                            <h2>⚠️ Production Deployment Approval Required</h2>
                            <p><strong>Job:</strong> ${env.JOB_NAME} #${env.BUILD_NUMBER}</p>
                            <p><strong>Changes:</strong> ${env.GIT_COMMIT_MSG}</p>
                            <p><strong>Author:</strong> ${env.GIT_AUTHOR}</p>
                            <p><strong>Approve:</strong> <a href="${env.BUILD_URL}input">Click here to approve</a></p>
                        """,
                        mimeType: 'text/html'
                    )
                    
                    timeout(time: 30, unit: 'MINUTES') {
                        input(
                            message: 'Deploy to Production?',
                            ok: 'Deploy',
                            submitter: 'devops-team,tech-leads',
                            submitterParameter: 'APPROVER'
                        )
                    }
                }
            }
        }

        //----------------------------------------------------------------------
        // Stage 10: Production Deployment
        //----------------------------------------------------------------------
        stage('Deploy to Production') {
            when {
                expression { params.ENVIRONMENT == 'prod' }
            }
            steps {
                script {
                    withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', 
                                      credentialsId: 'aws-credentials']]) {
                        sh """
                            aws eks update-kubeconfig --region ${AWS_REGION} --name ${EKS_CLUSTER_NAME}
                            
                            # Deploy with canary strategy for production
                            scripts/deploy.sh backend ${IMAGE_TAG} prod --canary
                            scripts/deploy.sh frontend ${IMAGE_TAG} prod --canary
                        """
                    }
                }
            }
        }

        //----------------------------------------------------------------------
        // Stage 11: Smoke Tests
        //----------------------------------------------------------------------
        stage('Smoke Tests') {
            steps {
                script {
                    echo "=========================================="
                    echo "Stage: Post-Deployment Smoke Tests"
                    echo "=========================================="
                    
                    sh '''
                        # Wait for deployments to stabilize
                        sleep 30
                        
                        # Run smoke tests
                        chmod +x scripts/smoke-test.sh
                        scripts/smoke-test.sh ${ENVIRONMENT}
                    '''
                }
            }
        }

        //----------------------------------------------------------------------
        // Stage 12: Cleanup
        //----------------------------------------------------------------------
        stage('Cleanup') {
            steps {
                script {
                    echo "=========================================="
                    echo "Stage: Cleanup"
                    echo "=========================================="
                    
                    sh '''
                        # Remove local Docker images to save space
                        docker image prune -f
                        docker system prune -f --volumes || true
                    '''
                }
            }
        }
    }

    //--------------------------------------------------------------------------
    // Post-Build Actions
    //--------------------------------------------------------------------------
    post {
        success {
            script {
                emailext(
                    to: env.EMAIL_RECIPIENTS,
                    subject: "✅ Deployment Successful - ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                    body: """
                        <h2>✅ Deployment Successful</h2>
                        <p><strong>Job:</strong> ${env.JOB_NAME} #${env.BUILD_NUMBER}</p>
                        <p><strong>Environment:</strong> ${params.ENVIRONMENT}</p>
                        <p><strong>Duration:</strong> ${currentBuild.durationString}</p>
                        <p><strong>Changes:</strong> ${env.GIT_COMMIT_MSG}</p>
                        <p><strong>Author:</strong> ${env.GIT_AUTHOR}</p>
                    """,
                    mimeType: 'text/html'
                )
            }
        }
        failure {
            script {
                emailext(
                    to: env.EMAIL_RECIPIENTS,
                    subject: "❌ Deployment Failed - ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                    body: """
                        <h2>❌ Deployment Failed</h2>
                        <p><strong>Job:</strong> ${env.JOB_NAME} #${env.BUILD_NUMBER}</p>
                        <p><strong>Environment:</strong> ${params.ENVIRONMENT}</p>
                        <p><strong>Failed Stage:</strong> ${env.STAGE_NAME}</p>
                        <p><strong>Console Output:</strong> <a href="${env.BUILD_URL}console">View Logs</a></p>
                        <p><strong>Changes:</strong> ${env.GIT_COMMIT_MSG}</p>
                        <p><strong>Author:</strong> ${env.GIT_AUTHOR}</p>
                    """,
                    mimeType: 'text/html'
                )
                
                // Trigger rollback for production failures
                if (params.ENVIRONMENT == 'prod') {
                    sh '''
                        chmod +x scripts/rollback.sh
                        scripts/rollback.sh backend prod
                        scripts/rollback.sh frontend prod
                    '''
                }
            }
        }
        always {
            cleanWs()
        }
    }
}
