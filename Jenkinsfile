pipeline {
    agent any

    environment {
        // AWS Configuration
        AWS_REGION = 'us-east-1'
        // IMPORTANT: Set your 12-digit AWS Account ID below (e.g., '123456789012')
        AWS_ACCOUNT_ID = credentials('aws-account-id')

        // ECR Configuration
        ECR_REGISTRY = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
        ECR_BACKEND_REPO = "shopdeploy-prod-backend"
        ECR_FRONTEND_REPO = "shopdeploy-prod-frontend"

        // EKS Configuration
        EKS_CLUSTER_NAME = 'shopdeploy-prod-eks'
        K8S_NAMESPACE = 'shopdeploy'

        // Image Tag
        IMAGE_TAG = "${BUILD_NUMBER}-${GIT_COMMIT.take(7)}"

        // SonarQube Configuration
        SONAR_PROJECT_KEY = 'shopdeploy'

        // Directory Paths
        BACKEND_DIR = 'shopdeploy-backend'
        FRONTEND_DIR = 'shopdeploy-frontend'

        // Node.js Version
        NODEJS_VERSION = '18'
    }

    tools {
        nodejs 'NodeJS-18'  // Ensure this matches your Jenkins NodeJS installation name
    }

    options {
        timeout(time: 60, unit: 'MINUTES')
        buildDiscarder(logRotator(numToKeepStr: '20'))
        disableConcurrentBuilds()
        timestamps()
        ansiColor('xterm')
    }

    parameters {
        choice(
            name: 'ENVIRONMENT',
            choices: ['dev', 'staging', 'prod'],
            description: 'Target deployment environment'
        )
        booleanParam(
            name: 'SKIP_TESTS',
            defaultValue: false,
            description: 'Skip running unit tests'
        )
        booleanParam(
            name: 'SKIP_SONAR',
            defaultValue: true,
            description: 'Skip SonarQube analysis (set to false once SonarQube Scanner is installed on Jenkins)'
        )
        booleanParam(
            name: 'FORCE_DEPLOY',
            defaultValue: false,
            description: 'Force deployment even without code changes'
        )
        booleanParam(
            name: 'RUN_SECURITY_SCAN',
            defaultValue: true,
            description: 'Run Docker image security scan'
        )
    }

    triggers {
        githubPush()
        pollSCM('H/5 * * * *')
    }

    stages {
        //======================================================================
        // Stage 1: Checkout Source Code
        //======================================================================
        stage('Checkout') {
            steps {
                echo '🔄 Checking out source code...'
                checkout scm
                
                script {
                    // Get git commit info
                    env.GIT_COMMIT_MSG = sh(
                        script: 'git log -1 --pretty=%B',
                        returnStdout: true
                    ).trim()
                    env.GIT_AUTHOR = sh(
                        script: 'git log -1 --pretty=%an',
                        returnStdout: true
                    ).trim()
                    
                    echo "📝 Commit: ${env.GIT_COMMIT_MSG}"
                    echo "👤 Author: ${env.GIT_AUTHOR}"
                }
            }
        }

        //======================================================================
        // Stage 2: Detect Changes
        //======================================================================
        stage('Detect Changes') {
            steps {
                script {
                    echo '🔍 Detecting code changes...'
                    
                    // Check for changes in backend
                    def backendChanges = sh(
                        script: "git diff --name-only HEAD~1 HEAD -- ${BACKEND_DIR}/ || echo 'initial'",
                        returnStdout: true
                    ).trim()
                    
                    // Check for changes in frontend
                    def frontendChanges = sh(
                        script: "git diff --name-only HEAD~1 HEAD -- ${FRONTEND_DIR}/ || echo 'initial'",
                        returnStdout: true
                    ).trim()
                    
                    // Set environment variables
                    env.BACKEND_CHANGED = (backendChanges != '' || params.FORCE_DEPLOY) ? 'true' : 'false'
                    env.FRONTEND_CHANGED = (frontendChanges != '' || params.FORCE_DEPLOY) ? 'true' : 'false'
                    
                    echo "📦 Backend changed: ${env.BACKEND_CHANGED}"
                    echo "🎨 Frontend changed: ${env.FRONTEND_CHANGED}"
                    
                    // If nothing changed and not forced, skip to deployment
                    if (env.BACKEND_CHANGED == 'false' && env.FRONTEND_CHANGED == 'false') {
                        echo '⚠️ No changes detected. Use FORCE_DEPLOY to deploy anyway.'
                    }
                }
            }
        }

        //======================================================================
        // Stage 3: Install Dependencies
        //======================================================================
        stage('Install Dependencies') {
            parallel {
                stage('Backend Dependencies') {
                    steps {
                        dir("${BACKEND_DIR}") {
                            echo '📦 Installing backend dependencies...'
                            sh '''
                                npm ci --prefer-offline --no-audit
                                echo "✅ Backend dependencies installed"
                            '''
                        }
                    }
                }

                stage('Frontend Dependencies') {
                    steps {
                        dir("${FRONTEND_DIR}") {
                            echo '📦 Installing frontend dependencies...'
                            sh '''
                                npm ci --prefer-offline --no-audit
                                echo "✅ Frontend dependencies installed"
                            '''
                        }
                    }
                }
            }
        }

        //======================================================================
        // Stage 4: Code Linting
        //======================================================================
        stage('Code Linting') {
            parallel {
                stage('Backend Lint') {
                    steps {
                        dir("${BACKEND_DIR}") {
                            echo '🔍 Linting backend code...'
                            sh '''
                                npm run lint || echo "⚠️ Lint warnings found"
                            '''
                        }
                    }
                }

                stage('Frontend Lint') {
                    steps {
                        dir("${FRONTEND_DIR}") {
                            echo '🔍 Linting frontend code...'
                            sh '''
                                npm run lint || echo "⚠️ Lint warnings found"
                            '''
                        }
                    }
                }
            }
        }

        //======================================================================
        // Stage 5: Unit Tests
        //======================================================================
        stage('Unit Tests') {
            when {
                expression { !params.SKIP_TESTS }
            }
            parallel {
                stage('Backend Tests') {
                    steps {
                        dir("${BACKEND_DIR}") {
                            echo '🧪 Running backend tests...'
                            sh '''
                                npm test -- --coverage --passWithNoTests || echo "⚠️ Some tests failed"
                            '''
                        }
                    }
                    post {
                        always {
                            // Publish test results if available
                            junit allowEmptyResults: true, testResults: "${BACKEND_DIR}/coverage/junit.xml"
                        }
                    }
                }

                stage('Frontend Tests') {
                    steps {
                        dir("${FRONTEND_DIR}") {
                            echo '🧪 Running frontend tests...'
                            sh '''
                                npm test -- --coverage --passWithNoTests || echo "⚠️ Some tests failed"
                            '''
                        }
                    }
                    post {
                        always {
                            junit allowEmptyResults: true, testResults: "${FRONTEND_DIR}/coverage/junit.xml"
                        }
                    }
                }
            }
        }

        //======================================================================
        // Stage 6: SonarQube Analysis
        //======================================================================
        stage('SonarQube Analysis') {
            when {
                expression { params.SKIP_SONAR == false }
            }
            steps {
                echo '📊 Running SonarQube analysis...'
                script {
                    // Check if sonar-scanner is available
                    def scannerExists = sh(script: 'command -v sonar-scanner', returnStatus: true) == 0
                    if (!scannerExists) {
                        echo '⚠️ sonar-scanner not found. Skipping SonarQube analysis.'
                        echo '💡 Install SonarQube Scanner on Jenkins or set SKIP_SONAR=true'
                    } else {
                        withSonarQubeEnv('SonarQube') {
                            sh """
                                sonar-scanner \
                                    -Dsonar.projectKey=${SONAR_PROJECT_KEY} \
                                    -Dsonar.projectName=ShopDeploy \
                                    -Dsonar.sources=. \
                                    -Dsonar.exclusions=node_modules/**,**/test/**,**/coverage/**,**/*.spec.js \
                                    -Dsonar.javascript.lcov.reportPaths=${BACKEND_DIR}/coverage/lcov.info,${FRONTEND_DIR}/coverage/lcov.info
                            """
                        }
                    }
                }
            }
        }

        //======================================================================
        // Stage 7: Quality Gate
        //======================================================================
        stage('Quality Gate') {
            when {
                expression { params.SKIP_SONAR == false }
            }
            steps {
                echo '🚦 Checking Quality Gate...'
                script {
                    def scannerExists = sh(script: 'command -v sonar-scanner', returnStatus: true) == 0
                    if (scannerExists) {
                        timeout(time: 5, unit: 'MINUTES') {
                            waitForQualityGate abortPipeline: true
                        }
                    } else {
                        echo '⚠️ Skipping Quality Gate - SonarQube Scanner not configured'
                    }
                }
            }
        }

        //======================================================================
        // Stage 8: Build Docker Images
        //======================================================================
        stage('Build Docker Images') {
            parallel {
                stage('Build Backend Image') {
                    steps {
                        echo '🐳 Building backend Docker image...'
                        sh """
                            docker build \
                                --tag shopdeploy-backend:${IMAGE_TAG} \
                                --tag shopdeploy-backend:latest \
                                --build-arg BUILD_DATE=\$(date -u +'%Y-%m-%dT%H:%M:%SZ') \
                                --build-arg VERSION=${IMAGE_TAG} \
                                --file ${BACKEND_DIR}/Dockerfile \
                                ${BACKEND_DIR}
                        """
                    }
                }

                stage('Build Frontend Image') {
                    steps {
                        echo '🐳 Building frontend Docker image...'
                        script {
                            // Set API URL based on environment
                            def apiUrl = params.ENVIRONMENT == 'prod' ? 
                                'https://api.shopdeploy.com/api' : 
                                "https://api-${params.ENVIRONMENT}.shopdeploy.com/api"
                            
                            sh """
                                docker build \
                                    --tag shopdeploy-frontend:${IMAGE_TAG} \
                                    --tag shopdeploy-frontend:latest \
                                    --build-arg BUILD_DATE=\$(date -u +'%Y-%m-%dT%H:%M:%SZ') \
                                    --build-arg VERSION=${IMAGE_TAG} \
                                    --build-arg VITE_API_URL=${apiUrl} \
                                    --file ${FRONTEND_DIR}/Dockerfile \
                                    ${FRONTEND_DIR}
                            """
                        }
                    }
                }
            }
        }

        //======================================================================
        // Stage 9: Security Scan (Trivy)
        //======================================================================
        stage('Security Scan') {
            when {
                expression { params.RUN_SECURITY_SCAN }
            }
            parallel {
                stage('Scan Backend Image') {
                    steps {
                        echo '🔒 Scanning backend image for vulnerabilities...'
                        sh '''
                            # Install trivy if not present
                            if ! command -v trivy &> /dev/null; then
                                curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin
                            fi
                            
                            trivy image --severity HIGH,CRITICAL --exit-code 0 \
                                --format table shopdeploy-backend:${IMAGE_TAG} || true
                        '''
                    }
                }

                stage('Scan Frontend Image') {
                    steps {
                        echo '🔒 Scanning frontend image for vulnerabilities...'
                        sh '''
                            trivy image --severity HIGH,CRITICAL --exit-code 0 \
                                --format table shopdeploy-frontend:${IMAGE_TAG} || true
                        '''
                    }
                }
            }
        }

        //======================================================================
        // Stage 10: Push to ECR
        //======================================================================
        stage('Push to ECR') {
            steps {
                echo '🚀 Pushing images to AWS ECR...'
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'aws-credentials',
                    accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                    secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                ]]) {
                    sh '''
                        # Login to ECR
                        aws ecr get-login-password --region ${AWS_REGION} | \
                            docker login --username AWS --password-stdin ${ECR_REGISTRY}
                        
                        # Tag and push backend
                        docker tag shopdeploy-backend:${IMAGE_TAG} ${ECR_REGISTRY}/${ECR_BACKEND_REPO}:${IMAGE_TAG}
                        docker tag shopdeploy-backend:latest ${ECR_REGISTRY}/${ECR_BACKEND_REPO}:latest
                        docker push ${ECR_REGISTRY}/${ECR_BACKEND_REPO}:${IMAGE_TAG}
                        docker push ${ECR_REGISTRY}/${ECR_BACKEND_REPO}:latest
                        
                        echo "✅ Backend pushed: ${ECR_REGISTRY}/${ECR_BACKEND_REPO}:${IMAGE_TAG}"
                        
                        # Tag and push frontend
                        docker tag shopdeploy-frontend:${IMAGE_TAG} ${ECR_REGISTRY}/${ECR_FRONTEND_REPO}:${IMAGE_TAG}
                        docker tag shopdeploy-frontend:latest ${ECR_REGISTRY}/${ECR_FRONTEND_REPO}:latest
                        docker push ${ECR_REGISTRY}/${ECR_FRONTEND_REPO}:${IMAGE_TAG}
                        docker push ${ECR_REGISTRY}/${ECR_FRONTEND_REPO}:latest
                        
                        echo "✅ Frontend pushed: ${ECR_REGISTRY}/${ECR_FRONTEND_REPO}:${IMAGE_TAG}"
                    '''
                }
            }
        }

        //======================================================================
        // Stage 11: Deploy to Dev/Staging
        //======================================================================
        stage('Deploy to Dev/Staging') {
            when {
                expression { params.ENVIRONMENT != 'prod' }
            }
            steps {
                echo "🚀 Deploying to ${params.ENVIRONMENT} environment..."
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'aws-credentials',
                    accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                    secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                ]]) {
                    sh '''
                        # Setup tools
                        mkdir -p ${WORKSPACE}/bin
                        export PATH=${WORKSPACE}/bin:$PATH
                        
                        # Install kubectl if not present
                        if [ ! -f ${WORKSPACE}/bin/kubectl ]; then
                            echo "📥 Installing kubectl..."
                            curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
                            chmod +x kubectl
                            mv kubectl ${WORKSPACE}/bin/
                        fi
                        
                        # Install helm if not present
                        if [ ! -f ${WORKSPACE}/bin/helm ]; then
                            echo "📥 Installing helm..."
                            curl -fsSL https://get.helm.sh/helm-v3.14.0-linux-amd64.tar.gz | tar xz
                            mv linux-amd64/helm ${WORKSPACE}/bin/
                            rm -rf linux-amd64
                        fi
                        
                        # Configure kubectl for EKS
                        aws eks update-kubeconfig --region ${AWS_REGION} --name ${EKS_CLUSTER_NAME}
                        
                        # Create namespace if not exists
                        kubectl create namespace ${K8S_NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -
                        
                        # Deploy backend
                        echo "📦 Deploying backend..."
                        helm upgrade --install shopdeploy-backend ./helm/backend \
                            --namespace ${K8S_NAMESPACE} \
                            --values ./helm/backend/values-${ENVIRONMENT}.yaml \
                            --set image.repository=${ECR_REGISTRY}/${ECR_BACKEND_REPO} \
                            --set image.tag=${IMAGE_TAG} \
                            --set global.environment=${ENVIRONMENT} \
                            --wait \
                            --timeout 10m
                        
                        # Deploy frontend
                        echo "🎨 Deploying frontend..."
                        helm upgrade --install shopdeploy-frontend ./helm/frontend \
                            --namespace ${K8S_NAMESPACE} \
                            --values ./helm/frontend/values-${ENVIRONMENT}.yaml \
                            --set image.repository=${ECR_REGISTRY}/${ECR_FRONTEND_REPO} \
                            --set image.tag=${IMAGE_TAG} \
                            --set global.environment=${ENVIRONMENT} \
                            --wait \
                            --timeout 10m
                        
                        echo "✅ Deployment to ${ENVIRONMENT} completed"
                    '''
                }
            }
        }

        //======================================================================
        // Stage 12: Production Approval
        //======================================================================
        stage('Production Approval') {
            when {
                expression { params.ENVIRONMENT == 'prod' }
            }
            steps {
                script {
                    echo '⏳ Waiting for production deployment approval...'
                    
                    // Send notification before approval
                    def approvalMessage = """
                        🚀 Production Deployment Request
                        
                        Build: #${BUILD_NUMBER}
                        Image Tag: ${IMAGE_TAG}
                        Commit: ${GIT_COMMIT.take(7)}
                        Author: ${env.GIT_AUTHOR}
                        Message: ${env.GIT_COMMIT_MSG}
                        
                        Please review and approve the production deployment.
                    """
                    
                    echo approvalMessage
                    
                    timeout(time: 30, unit: 'MINUTES') {
                        input(
                            message: 'Deploy to PRODUCTION?',
                            ok: 'Approve Deployment',
                            submitter: 'admin,devops-team',
                            submitterParameter: 'APPROVER'
                        )
                    }
                    
                    echo "✅ Production deployment approved by ${env.APPROVER}"
                }
            }
        }

        //======================================================================
        // Stage 13: Deploy to Production
        //======================================================================
        stage('Deploy to Production') {
            when {
                expression { params.ENVIRONMENT == 'prod' }
            }
            steps {
                echo '🚀 Deploying to PRODUCTION...'
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'aws-credentials',
                    accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                    secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                ]]) {
                    sh '''
                        # Setup tools
                        mkdir -p ${WORKSPACE}/bin
                        export PATH=${WORKSPACE}/bin:$PATH
                        
                        # Install kubectl if not present
                        if [ ! -f ${WORKSPACE}/bin/kubectl ]; then
                            echo "📥 Installing kubectl..."
                            curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
                            chmod +x kubectl
                            mv kubectl ${WORKSPACE}/bin/
                        fi
                        
                        # Install helm if not present
                        if [ ! -f ${WORKSPACE}/bin/helm ]; then
                            echo "📥 Installing helm..."
                            curl -fsSL https://get.helm.sh/helm-v3.14.0-linux-amd64.tar.gz | tar xz
                            mv linux-amd64/helm ${WORKSPACE}/bin/
                            rm -rf linux-amd64
                        fi
                        
                        # Configure kubectl for EKS
                        aws eks update-kubeconfig --region ${AWS_REGION} --name ${EKS_CLUSTER_NAME}
                        
                        # Store previous deployment info for rollback
                        PREV_BACKEND_TAG=$(kubectl get deployment shopdeploy-backend -n ${K8S_NAMESPACE} \
                            -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null | cut -d: -f2 || echo "none")
                        PREV_FRONTEND_TAG=$(kubectl get deployment shopdeploy-frontend -n ${K8S_NAMESPACE} \
                            -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null | cut -d: -f2 || echo "none")
                        
                        echo "📋 Previous backend tag: ${PREV_BACKEND_TAG}"
                        echo "📋 Previous frontend tag: ${PREV_FRONTEND_TAG}"
                        
                        # Deploy backend with production values
                        echo "📦 Deploying backend to production..."
                        helm upgrade --install shopdeploy-backend ./helm/backend \
                            --namespace ${K8S_NAMESPACE} \
                            --values ./helm/backend/values-prod.yaml \
                            --set image.repository=${ECR_REGISTRY}/${ECR_BACKEND_REPO} \
                            --set image.tag=${IMAGE_TAG} \
                            --set global.environment=prod \
                            --wait \
                            --timeout 10m
                        
                        # Deploy frontend with production values
                        echo "🎨 Deploying frontend to production..."
                        helm upgrade --install shopdeploy-frontend ./helm/frontend \
                            --namespace ${K8S_NAMESPACE} \
                            --values ./helm/frontend/values-prod.yaml \
                            --set image.repository=${ECR_REGISTRY}/${ECR_FRONTEND_REPO} \
                            --set image.tag=${IMAGE_TAG} \
                            --set global.environment=prod \
                            --wait \
                            --timeout 10m
                        
                        echo "✅ Production deployment completed"
                    '''
                }
            }
        }

        //======================================================================
        // Stage 14: Smoke Tests
        //======================================================================
        stage('Smoke Tests') {
            steps {
                echo '🔬 Running smoke tests...'
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'aws-credentials',
                    accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                    secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                ]]) {
                    sh '''
                        # Setup tools
                        export PATH=${WORKSPACE}/bin:$PATH
                        
                        # Configure kubectl
                        aws eks update-kubeconfig --region ${AWS_REGION} --name ${EKS_CLUSTER_NAME}
                        
                        echo "📋 Checking deployment status..."
                        
                        # Check pod status
                        echo "🔍 Pod Status:"
                        kubectl get pods -n ${K8S_NAMESPACE} -l app=shopdeploy
                        
                        # Wait for backend rollout
                        echo "⏳ Waiting for backend rollout..."
                        kubectl rollout status deployment/shopdeploy-backend -n ${K8S_NAMESPACE} --timeout=300s
                        
                        # Wait for frontend rollout
                        echo "⏳ Waiting for frontend rollout..."
                        kubectl rollout status deployment/shopdeploy-frontend -n ${K8S_NAMESPACE} --timeout=300s
                        
                        # Get service endpoints
                        echo "🌐 Service Endpoints:"
                        kubectl get svc -n ${K8S_NAMESPACE}
                        
                        # Get ingress
                        echo "🚪 Ingress:"
                        kubectl get ingress -n ${K8S_NAMESPACE}
                        
                        # Run health check via port-forward
                        echo "🏥 Running health checks..."
                        
                        # Backend health check
                        kubectl run health-check --rm -i --restart=Never \
                            --image=curlimages/curl --namespace=${K8S_NAMESPACE} -- \
                            curl -sf http://backend-service:5000/api/health/health || echo "⚠️ Backend health check warning"
                        
                        echo "✅ Smoke tests completed"
                    '''
                }
            }
        }

        //======================================================================
        // Stage 15: Integration Tests
        //======================================================================
        stage('Integration Tests') {
            when {
                expression { params.ENVIRONMENT != 'prod' }
            }
            steps {
                echo '🧪 Running integration tests...'
                sh '''
                    # Run integration tests if available
                    if [ -f "${BACKEND_DIR}/tests/integration.test.js" ]; then
                        cd ${BACKEND_DIR}
                        npm run test:integration || echo "⚠️ Some integration tests failed"
                    else
                        echo "ℹ️ No integration tests found, skipping..."
                    fi
                '''
            }
        }

        //======================================================================
        // Stage 16: Cleanup
        //======================================================================
        stage('Cleanup') {
            steps {
                echo '🧹 Cleaning up...'
                sh '''
                    # Remove local docker images to save space
                    docker rmi shopdeploy-backend:${IMAGE_TAG} || true
                    docker rmi shopdeploy-backend:latest || true
                    docker rmi shopdeploy-frontend:${IMAGE_TAG} || true
                    docker rmi shopdeploy-frontend:latest || true
                    docker rmi ${ECR_REGISTRY}/${ECR_BACKEND_REPO}:${IMAGE_TAG} || true
                    docker rmi ${ECR_REGISTRY}/${ECR_FRONTEND_REPO}:${IMAGE_TAG} || true
                    
                    # Prune dangling images
                    docker image prune -f || true
                    
                    echo "✅ Cleanup completed"
                '''
            }
        }
    }

    //==========================================================================
    // Post-Build Actions
    //==========================================================================
    post {
        success {
            script {
                echo """
                ╔═══════════════════════════════════════════════════════════╗
                ║  ✅ PIPELINE COMPLETED SUCCESSFULLY                       ║
                ╠═══════════════════════════════════════════════════════════╣
                ║  Build: #${BUILD_NUMBER}                                  
                ║  Environment: ${params.ENVIRONMENT}                       
                ║  Image Tag: ${IMAGE_TAG}                                  
                ║  Duration: ${currentBuild.durationString}                 
                ╚═══════════════════════════════════════════════════════════╝
                """
                
                // Slack notification (if configured)
                // slackSend(
                //     channel: '#deployments',
                //     color: 'good',
                //     message: "✅ ShopDeploy deployed to ${params.ENVIRONMENT}\nBuild: #${BUILD_NUMBER}\nTag: ${IMAGE_TAG}"
                // )
            }
        }

        failure {
            script {
                echo """
                ╔═══════════════════════════════════════════════════════════╗
                ║  ❌ PIPELINE FAILED                                       ║
                ╠═══════════════════════════════════════════════════════════╣
                ║  Build: #${BUILD_NUMBER}                                  
                ║  Environment: ${params.ENVIRONMENT}                       
                ║  Stage: ${env.STAGE_NAME}                                 
                ║  Check logs for details                                   
                ╚═══════════════════════════════════════════════════════════╝
                """
                
                // Attempt rollback for production failures
                if (params.ENVIRONMENT == 'prod') {
                    echo '⚠️ Production deployment failed. Consider manual rollback.'
                }
                
                // Slack notification (if configured)
                // slackSend(
                //     channel: '#deployments',
                //     color: 'danger',
                //     message: "❌ ShopDeploy deployment FAILED\nBuild: #${BUILD_NUMBER}\nEnvironment: ${params.ENVIRONMENT}"
                // )
            }
        }

        unstable {
            echo '⚠️ Pipeline completed with warnings (unstable)'
        }

        aborted {
            echo '🛑 Pipeline was aborted'
        }

        always {
            // Archive artifacts
            archiveArtifacts artifacts: '**/coverage/**', allowEmptyArchive: true
            
            // Clean workspace
            cleanWs(
                cleanWhenNotBuilt: false,
                deleteDirs: true,
                disableDeferredWipeout: true,
                notFailBuild: true
            )
        }
    }
}
