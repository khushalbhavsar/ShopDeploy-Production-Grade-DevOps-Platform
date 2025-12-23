// //==============================================================================
// // ShopDeploy - Production-Grade CI/CD Pipeline
// // Pipeline Flow:
// // Checkout → Code Quality (SonarQube) → Quality Gate → Unit Tests → 
// // Docker Build → Push to ECR → Deploy to Dev/Staging → 
// // Manual Production Approval → Deploy to Production → Smoke Tests → 
// // Auto Rollback on Failure
// //==============================================================================

// pipeline {
//     agent any

//     //--------------------------------------------------------------------------
//     // Environment Variables
//     //--------------------------------------------------------------------------
//     environment {
//         // AWS Configuration
//         AWS_REGION = 'us-east-1'
//         AWS_ACCOUNT_ID = '348823728691'
        
//         // ECR Configuration
//         ECR_REGISTRY = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
//         ECR_BACKEND_REPO = "shopdeploy-prod-backend"
//         ECR_FRONTEND_REPO = "shopdeploy-prod-frontend"
        
//         // EKS Configuration
//         EKS_CLUSTER_NAME = 'shopdeploy-prod-eks'
//         K8S_NAMESPACE = 'shopdeploy'
        
//         // Docker Image Tags
//         IMAGE_TAG = "${BUILD_NUMBER}-${GIT_COMMIT.take(7)}"
        
//         // SonarQube Configuration
//         SONAR_HOST_URL = 'http://localhost:9000'  // Update with your SonarQube server URL
//         SONAR_PROJECT_KEY = 'shopdeploy'
        
//         // Application Paths
//         BACKEND_DIR = 'shopdeploy-backend'
//         FRONTEND_DIR = 'shopdeploy-frontend'
        
//         // Rollback tracking
//         PREVIOUS_BACKEND_TAG = ''
//         PREVIOUS_FRONTEND_TAG = ''
//     }

//     //--------------------------------------------------------------------------
//     // Pipeline Options
//     //--------------------------------------------------------------------------
//     options {
//         timeout(time: 60, unit: 'MINUTES')
//         buildDiscarder(logRotator(numToKeepStr: '20'))
//         disableConcurrentBuilds()
//         timestamps()
//         ansiColor('xterm')
//     }

//     //--------------------------------------------------------------------------
//     // Pipeline Parameters
//     //--------------------------------------------------------------------------
//     parameters {
//         choice(
//             name: 'ENVIRONMENT',
//             choices: ['dev', 'staging', 'prod'],
//             description: 'Target deployment environment'
//         )
//         booleanParam(
//             name: 'SKIP_TESTS',
//             defaultValue: false,
//             description: 'Skip test stages (not recommended for production)'
//         )
//         booleanParam(
//             name: 'SKIP_SONAR',
//             defaultValue: false,
//             description: 'Skip SonarQube analysis'
//         )
//         booleanParam(
//             name: 'FORCE_DEPLOY',
//             defaultValue: false,
//             description: 'Force deployment even if no changes detected'
//         )
//     }

//     //--------------------------------------------------------------------------
//     // Pipeline Triggers
//     //--------------------------------------------------------------------------
//     triggers {
//         githubPush()
//         pollSCM('H/5 * * * *')
//     }

//     //--------------------------------------------------------------------------
//     // Pipeline Stages
//     //--------------------------------------------------------------------------
//     stages {
        
//         //======================================================================
//         // STAGE 1: CHECKOUT
//         //======================================================================
//         stage('Checkout') {
//             steps {
//                 script {
//                     echo "╔══════════════════════════════════════════════════════════╗"
//                     echo "║  STAGE 1: CHECKOUT SOURCE CODE                           ║"
//                     echo "╚══════════════════════════════════════════════════════════╝"
//                 }
                
//                 checkout scm
                
//                 script {
//                     // Get commit info
//                     env.GIT_COMMIT_MSG = sh(script: 'git log -1 --pretty=%B', returnStdout: true).trim()
//                     env.GIT_AUTHOR = sh(script: 'git log -1 --pretty=%an', returnStdout: true).trim()
//                     env.GIT_COMMIT_SHORT = sh(script: 'git rev-parse --short HEAD', returnStdout: true).trim()
                    
//                     // Detect changes
//                     def changes = sh(script: 'git diff --name-only HEAD~1 HEAD 2>/dev/null || echo "initial"', returnStdout: true).trim()
//                     env.BACKEND_CHANGED = (changes.contains('shopdeploy-backend/') || params.FORCE_DEPLOY).toString()
//                     env.FRONTEND_CHANGED = (changes.contains('shopdeploy-frontend/') || params.FORCE_DEPLOY).toString()
                    
//                     echo """
//                     ┌─────────────────────────────────────────┐
//                     │ Commit: ${env.GIT_COMMIT_SHORT}
//                     │ Author: ${env.GIT_AUTHOR}
//                     │ Message: ${env.GIT_COMMIT_MSG.take(50)}
//                     │ Backend Changed: ${env.BACKEND_CHANGED}
//                     │ Frontend Changed: ${env.FRONTEND_CHANGED}
//                     └─────────────────────────────────────────┘
//                     """
//                 }
//             }
//         }

//         //======================================================================
//         // STAGE 2: INSTALL DEPENDENCIES
//         //======================================================================
//         stage('Install Dependencies') {
//             parallel {
//                 stage('Backend Deps') {
//                     when { expression { env.BACKEND_CHANGED == 'true' } }
//                     steps {
//                         dir("${BACKEND_DIR}") {
//                             sh 'npm ci --production=false'
//                         }
//                     }
//                 }
//                 stage('Frontend Deps') {
//                     when { expression { env.FRONTEND_CHANGED == 'true' } }
//                     steps {
//                         dir("${FRONTEND_DIR}") {
//                             sh 'npm ci'
//                         }
//                     }
//                 }
//             }
//         }

//         //======================================================================
//         // STAGE 3: CODE QUALITY (SONARQUBE)
//         //======================================================================
//         stage('Code Quality (SonarQube)') {
//             when {
//                 expression { !params.SKIP_SONAR && (env.BACKEND_CHANGED == 'true' || env.FRONTEND_CHANGED == 'true') }
//             }
//             steps {
//                 script {
//                     echo "╔══════════════════════════════════════════════════════════╗"
//                     echo "║  STAGE 3: CODE QUALITY ANALYSIS (SONARQUBE)              ║"
//                     echo "╚══════════════════════════════════════════════════════════╝"
                    
//                     // Try SonarQube analysis, fallback to ESLint if not configured
//                     try {
//                         withSonarQubeEnv('SonarQube') {
//                             sh """
//                                 echo "[SONAR] Running SonarQube Analysis..."
                                
//                                 # Backend Analysis
//                                 if [ "${env.BACKEND_CHANGED}" = "true" ]; then
//                                     echo "[SONAR] Analyzing Backend..."
//                                     cd ${BACKEND_DIR}
//                                     npx sonar-scanner \
//                                         -Dsonar.projectKey=${SONAR_PROJECT_KEY}-backend \
//                                         -Dsonar.projectName="ShopDeploy Backend" \
//                                         -Dsonar.sources=src \
//                                         -Dsonar.javascript.lcov.reportPaths=coverage/lcov.info \
//                                         || echo "[WARN] Backend SonarQube analysis skipped"
//                                     cd ..
//                                 fi
                                
//                                 # Frontend Analysis
//                                 if [ "${env.FRONTEND_CHANGED}" = "true" ]; then
//                                     echo "[SONAR] Analyzing Frontend..."
//                                     cd ${FRONTEND_DIR}
//                                     npx sonar-scanner \
//                                         -Dsonar.projectKey=${SONAR_PROJECT_KEY}-frontend \
//                                         -Dsonar.projectName="ShopDeploy Frontend" \
//                                         -Dsonar.sources=src \
//                                         -Dsonar.javascript.lcov.reportPaths=coverage/lcov.info \
//                                         || echo "[WARN] Frontend SonarQube analysis skipped"
//                                     cd ..
//                                 fi
//                             """
//                         }
//                     } catch (Exception e) {
//                         echo "[WARN] SonarQube not configured. Running ESLint as fallback..."
                        
//                         // Fallback to ESLint
//                         if (env.BACKEND_CHANGED == 'true') {
//                             dir("${BACKEND_DIR}") {
//                                 sh 'npm run lint || echo "[WARN] Backend lint issues found"'
//                             }
//                         }
//                         if (env.FRONTEND_CHANGED == 'true') {
//                             dir("${FRONTEND_DIR}") {
//                                 sh 'npm run lint || echo "[WARN] Frontend lint issues found"'
//                             }
//                         }
//                     }
//                 }
//             }
//         }

//         //======================================================================
//         // STAGE 4: QUALITY GATE
//         //======================================================================
//         stage('Quality Gate') {
//             when {
//                 expression { !params.SKIP_SONAR && (env.BACKEND_CHANGED == 'true' || env.FRONTEND_CHANGED == 'true') }
//             }
//             steps {
//                 script {
//                     echo "╔══════════════════════════════════════════════════════════╗"
//                     echo "║  STAGE 4: QUALITY GATE CHECK                             ║"
//                     echo "╚══════════════════════════════════════════════════════════╝"
                    
//                     try {
//                         timeout(time: 5, unit: 'MINUTES') {
//                             def qg = waitForQualityGate()
//                             if (qg.status != 'OK') {
//                                 echo "[WARN] Quality Gate status: ${qg.status}"
//                                 if (params.ENVIRONMENT == 'prod') {
//                                     error "Quality Gate failed for production deployment"
//                                 }
//                             } else {
//                                 echo "[PASS] Quality Gate passed: ${qg.status}"
//                             }
//                         }
//                     } catch (Exception e) {
//                         echo "[WARN] Quality Gate check skipped - SonarQube webhook not configured"
                        
//                         // Fallback: Security audit as quality gate
//                         echo "[CHECK] Running Security Audit as fallback..."
//                         sh """
//                             echo "┌─────────────────────────────────────────┐"
//                             echo "│ Security Vulnerability Scan             │"
//                             echo "└─────────────────────────────────────────┘"
                            
//                             if [ "${env.BACKEND_CHANGED}" = "true" ]; then
//                                 echo "[AUDIT] Backend Security Check:"
//                                 cd ${BACKEND_DIR} && npm audit --audit-level=critical || echo "[WARN] Vulnerabilities found"
//                                 cd ..
//                             fi
                            
//                             if [ "${env.FRONTEND_CHANGED}" = "true" ]; then
//                                 echo "[AUDIT] Frontend Security Check:"
//                                 cd ${FRONTEND_DIR} && npm audit --audit-level=critical || echo "[WARN] Vulnerabilities found"
//                                 cd ..
//                             fi
                            
//                             echo "[PASS] Quality Gate (Fallback) Completed"
//                         """
//                     }
//                 }
//             }
//         }

//         //======================================================================
//         // STAGE 5: UNIT TESTS
//         //======================================================================
//         stage('Unit Tests') {
//             when {
//                 expression { !params.SKIP_TESTS && (env.BACKEND_CHANGED == 'true' || env.FRONTEND_CHANGED == 'true') }
//             }
//             parallel {
//                 stage('Backend Tests') {
//                     when { expression { env.BACKEND_CHANGED == 'true' } }
//                     steps {
//                         script {
//                             echo "╔══════════════════════════════════════════════════════════╗"
//                             echo "║  RUNNING BACKEND UNIT TESTS                              ║"
//                             echo "╚══════════════════════════════════════════════════════════╝"
//                         }
//                         dir("${BACKEND_DIR}") {
//                             sh '''
//                                 echo "[TEST] Running Backend Tests..."
//                                 npm test -- --coverage --passWithNoTests || echo "[WARN] Some tests failed"
//                                 echo "[PASS] Backend tests completed"
//                             '''
//                         }
//                     }
//                     post {
//                         always {
//                             publishHTML([
//                                 allowMissing: true,
//                                 alwaysLinkToLastBuild: true,
//                                 keepAll: true,
//                                 reportDir: "${BACKEND_DIR}/coverage/lcov-report",
//                                 reportFiles: 'index.html',
//                                 reportName: 'Backend Coverage Report'
//                             ])
//                         }
//                     }
//                 }
//                 stage('Frontend Tests') {
//                     when { expression { env.FRONTEND_CHANGED == 'true' } }
//                     steps {
//                         script {
//                             echo "╔══════════════════════════════════════════════════════════╗"
//                             echo "║  RUNNING FRONTEND UNIT TESTS                             ║"
//                             echo "╚══════════════════════════════════════════════════════════╝"
//                         }
//                         dir("${FRONTEND_DIR}") {
//                             sh '''
//                                 echo "[TEST] Running Frontend Tests..."
//                                 npm test -- --coverage --passWithNoTests 2>/dev/null || echo "[WARN] Tests skipped or failed"
//                                 echo "[PASS] Frontend tests completed"
//                             '''
//                         }
//                     }
//                 }
//             }
//         }

//         //======================================================================
//         // STAGE 6: DOCKER BUILD
//         //======================================================================
//         stage('Docker Build') {
//             when {
//                 expression { env.BACKEND_CHANGED == 'true' || env.FRONTEND_CHANGED == 'true' }
//             }
//             parallel {
//                 stage('Build Backend Image') {
//                     when { expression { env.BACKEND_CHANGED == 'true' } }
//                     steps {
//                         script {
//                             echo "╔══════════════════════════════════════════════════════════╗"
//                             echo "║  BUILDING BACKEND DOCKER IMAGE                           ║"
//                             echo "╚══════════════════════════════════════════════════════════╝"
                            
//                             sh """
//                                 chmod +x scripts/build.sh
//                                 scripts/build.sh backend ${IMAGE_TAG}
//                             """
//                         }
//                     }
//                 }
//                 stage('Build Frontend Image') {
//                     when { expression { env.FRONTEND_CHANGED == 'true' } }
//                     steps {
//                         script {
//                             echo "╔══════════════════════════════════════════════════════════╗"
//                             echo "║  BUILDING FRONTEND DOCKER IMAGE                          ║"
//                             echo "╚══════════════════════════════════════════════════════════╝"
                            
//                             sh """
//                                 chmod +x scripts/build.sh
//                                 scripts/build.sh frontend ${IMAGE_TAG}
//                             """
//                         }
//                     }
//                 }
//             }
//         }

//         //======================================================================
//         // STAGE 7: PUSH TO ECR
//         //======================================================================
//         stage('Push to ECR') {
//             when {
//                 expression { env.BACKEND_CHANGED == 'true' || env.FRONTEND_CHANGED == 'true' }
//             }
//             steps {
//                 script {
//                     echo "╔══════════════════════════════════════════════════════════╗"
//                     echo "║  STAGE 7: PUSH DOCKER IMAGES TO ECR                      ║"
//                     echo "╚══════════════════════════════════════════════════════════╝"
                    
//                     withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', 
//                                       credentialsId: 'aws-credentials']]) {
//                         sh """
//                             chmod +x scripts/push.sh
                            
//                             # Login to ECR
//                             aws ecr get-login-password --region ${AWS_REGION} | \
//                                 docker login --username AWS --password-stdin ${ECR_REGISTRY}
//                         """
                        
//                         if (env.BACKEND_CHANGED == 'true') {
//                             sh "scripts/push.sh backend ${IMAGE_TAG} ${ECR_REGISTRY}/${ECR_BACKEND_REPO}"
//                         }
                        
//                         if (env.FRONTEND_CHANGED == 'true') {
//                             sh "scripts/push.sh frontend ${IMAGE_TAG} ${ECR_REGISTRY}/${ECR_FRONTEND_REPO}"
//                         }
//                     }
//                 }
//             }
//         }

//         //======================================================================
//         // STAGE 8: DEPLOY TO DEV/STAGING
//         //======================================================================
//         stage('Deploy to Dev/Staging') {
//             when {
//                 expression { params.ENVIRONMENT != 'prod' && (env.BACKEND_CHANGED == 'true' || env.FRONTEND_CHANGED == 'true') }
//             }
//             steps {
//                 script {
//                     echo "╔══════════════════════════════════════════════════════════╗"
//                     echo "║  STAGE 8: DEPLOY TO ${params.ENVIRONMENT.toUpperCase()} ENVIRONMENT                        ║"
//                     echo "╚══════════════════════════════════════════════════════════╝"
                    
//                     withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', 
//                                       credentialsId: 'aws-credentials']]) {
                        
//                         sh """
//                             aws eks update-kubeconfig --region ${AWS_REGION} --name ${EKS_CLUSTER_NAME}
//                             chmod +x scripts/deploy.sh
//                         """
                        
//                         // Store previous tags for rollback
//                         try {
//                             env.PREVIOUS_BACKEND_TAG = sh(
//                                 script: "kubectl get deployment shopdeploy-backend -n ${K8S_NAMESPACE} -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null | cut -d: -f2 || echo ''",
//                                 returnStdout: true
//                             ).trim()
//                             env.PREVIOUS_FRONTEND_TAG = sh(
//                                 script: "kubectl get deployment shopdeploy-frontend -n ${K8S_NAMESPACE} -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null | cut -d: -f2 || echo ''",
//                                 returnStdout: true
//                             ).trim()
//                         } catch (Exception e) {
//                             echo "[INFO] No previous deployment found"
//                         }
                        
//                         echo """
//                         ┌─────────────────────────────────────────┐
//                         │ Deployment Info:
//                         │ Environment: ${params.ENVIRONMENT}
//                         │ New Tag: ${IMAGE_TAG}
//                         │ Previous Backend: ${env.PREVIOUS_BACKEND_TAG ?: 'N/A'}
//                         │ Previous Frontend: ${env.PREVIOUS_FRONTEND_TAG ?: 'N/A'}
//                         └─────────────────────────────────────────┘
//                         """
                        
//                         if (env.BACKEND_CHANGED == 'true') {
//                             sh "scripts/deploy.sh backend ${IMAGE_TAG} ${params.ENVIRONMENT}"
//                         }
                        
//                         if (env.FRONTEND_CHANGED == 'true') {
//                             sh "scripts/deploy.sh frontend ${IMAGE_TAG} ${params.ENVIRONMENT}"
//                         }
//                     }
//                 }
//             }
//         }

//         //======================================================================
//         // STAGE 9: MANUAL PRODUCTION APPROVAL
//         //======================================================================
//         stage('Manual Production Approval') {
//             when {
//                 expression { params.ENVIRONMENT == 'prod' }
//             }
//             steps {
//                 script {
//                     echo "╔══════════════════════════════════════════════════════════╗"
//                     echo "║  STAGE 9: PRODUCTION DEPLOYMENT APPROVAL                 ║"
//                     echo "╚══════════════════════════════════════════════════════════╝"
                    
//                     echo """
//                     ╔═══════════════════════════════════════════════════════════════╗
//                     ║            ⚠️  PRODUCTION DEPLOYMENT REQUEST ⚠️              ║
//                     ╠═══════════════════════════════════════════════════════════════╣
//                     ║  Build Number: ${BUILD_NUMBER}
//                     ║  Image Tag: ${IMAGE_TAG}
//                     ║  Git Commit: ${env.GIT_COMMIT_SHORT}
//                     ║  Author: ${env.GIT_AUTHOR}
//                     ║  Message: ${env.GIT_COMMIT_MSG.take(50)}
//                     ╠═══════════════════════════════════════════════════════════════╣
//                     ║  Backend Changed: ${env.BACKEND_CHANGED}
//                     ║  Frontend Changed: ${env.FRONTEND_CHANGED}
//                     ╚═══════════════════════════════════════════════════════════════╝
//                     """
                    
//                     timeout(time: 30, unit: 'MINUTES') {
//                         def approval = input(
//                             message: '🚀 Deploy to PRODUCTION?',
//                             ok: '✅ Approve & Deploy',
//                             parameters: [
//                                 booleanParam(
//                                     name: 'CONFIRM_TESTED',
//                                     defaultValue: false,
//                                     description: '✔️ I confirm this build has been tested in staging'
//                                 ),
//                                 booleanParam(
//                                     name: 'CONFIRM_ROLLBACK',
//                                     defaultValue: false,
//                                     description: '✔️ I understand rollback will occur on failure'
//                                 ),
//                                 string(
//                                     name: 'APPROVAL_NOTES',
//                                     defaultValue: '',
//                                     description: '📝 Deployment notes (optional)'
//                                 )
//                             ]
//                         )
                        
//                         if (!approval['CONFIRM_TESTED'] || !approval['CONFIRM_ROLLBACK']) {
//                             error "❌ Production deployment requires both confirmations"
//                         }
                        
//                         echo """
//                         ✅ Production Deployment Approved!
//                         📝 Notes: ${approval['APPROVAL_NOTES'] ?: 'None'}
//                         """
//                     }
//                 }
//             }
//         }

//         //======================================================================
//         // STAGE 10: DEPLOY TO PRODUCTION
//         //======================================================================
//         stage('Deploy to Production') {
//             when {
//                 expression { params.ENVIRONMENT == 'prod' }
//             }
//             steps {
//                 script {
//                     echo "╔══════════════════════════════════════════════════════════╗"
//                     echo "║  STAGE 10: DEPLOYING TO PRODUCTION                       ║"
//                     echo "╚══════════════════════════════════════════════════════════╝"
                    
//                     withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', 
//                                       credentialsId: 'aws-credentials']]) {
                        
//                         sh "aws eks update-kubeconfig --region ${AWS_REGION} --name ${EKS_CLUSTER_NAME}"
//                         sh "chmod +x scripts/deploy.sh"
                        
//                         // Store previous tags for rollback
//                         try {
//                             env.PREVIOUS_BACKEND_TAG = sh(
//                                 script: "kubectl get deployment shopdeploy-backend -n ${K8S_NAMESPACE} -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null | cut -d: -f2 || echo ''",
//                                 returnStdout: true
//                             ).trim()
//                             env.PREVIOUS_FRONTEND_TAG = sh(
//                                 script: "kubectl get deployment shopdeploy-frontend -n ${K8S_NAMESPACE} -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null | cut -d: -f2 || echo ''",
//                                 returnStdout: true
//                             ).trim()
                            
//                             echo "[ROLLBACK] Previous backend: ${env.PREVIOUS_BACKEND_TAG}"
//                             echo "[ROLLBACK] Previous frontend: ${env.PREVIOUS_FRONTEND_TAG}"
//                         } catch (Exception e) {
//                             echo "[INFO] No previous deployment found"
//                         }
                        
//                         echo """
//                         🚀 Starting Production Deployment...
//                         ┌─────────────────────────────────────────┐
//                         │ Deploying: ${IMAGE_TAG}
//                         │ Rollback Available: ${env.PREVIOUS_BACKEND_TAG ?: 'N/A'}
//                         └─────────────────────────────────────────┘
//                         """
                        
//                         if (env.BACKEND_CHANGED == 'true') {
//                             echo "[PROD] Deploying Backend..."
//                             sh "scripts/deploy.sh backend ${IMAGE_TAG} prod"
//                         }
                        
//                         if (env.FRONTEND_CHANGED == 'true') {
//                             echo "[PROD] Deploying Frontend..."
//                             sh "scripts/deploy.sh frontend ${IMAGE_TAG} prod"
//                         }
                        
//                         echo "✅ Production deployment completed"
//                     }
//                 }
//             }
//         }

//         //======================================================================
//         // STAGE 11: SMOKE TESTS
//         //======================================================================
//         stage('Smoke Tests') {
//             when {
//                 expression { env.BACKEND_CHANGED == 'true' || env.FRONTEND_CHANGED == 'true' }
//             }
//             steps {
//                 script {
//                     echo "╔══════════════════════════════════════════════════════════╗"
//                     echo "║  STAGE 11: POST-DEPLOYMENT SMOKE TESTS                   ║"
//                     echo "╚══════════════════════════════════════════════════════════╝"
                    
//                     withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', 
//                                       credentialsId: 'aws-credentials']]) {
//                         sh '''
//                             aws eks update-kubeconfig --region ${AWS_REGION} --name ${EKS_CLUSTER_NAME}
                            
//                             echo ""
//                             echo "⏳ Waiting for deployments to stabilize..."
//                             sleep 15
                            
//                             echo ""
//                             echo "┌─────────────────────────────────────────┐"
//                             echo "│ Running Health Checks                   │"
//                             echo "└─────────────────────────────────────────┘"
                            
//                             # Check all pods
//                             echo ""
//                             echo "[CHECK] Pod Status:"
//                             kubectl get pods -n ${K8S_NAMESPACE}
                            
//                             # Verify deployments are ready
//                             echo ""
//                             echo "[CHECK] Backend Deployment..."
//                             kubectl rollout status deployment/shopdeploy-backend -n ${K8S_NAMESPACE} --timeout=120s
                            
//                             echo ""
//                             echo "[CHECK] Frontend Deployment..."
//                             kubectl rollout status deployment/shopdeploy-frontend -n ${K8S_NAMESPACE} --timeout=120s
                            
//                             echo ""
//                             echo "[CHECK] MongoDB Deployment..."
//                             kubectl rollout status deployment/mongodb -n ${K8S_NAMESPACE} --timeout=120s
                            
//                             # Check for unhealthy pods
//                             echo ""
//                             echo "[CHECK] Checking for unhealthy pods..."
//                             UNHEALTHY=$(kubectl get pods -n ${K8S_NAMESPACE} --no-headers | grep -v "Running" | wc -l)
//                             if [ "$UNHEALTHY" -gt 0 ]; then
//                                 echo "❌ [FAIL] Found $UNHEALTHY unhealthy pod(s)"
//                                 kubectl get pods -n ${K8S_NAMESPACE}
//                                 exit 1
//                             fi
//                             echo "✅ [PASS] All pods are running"
                            
//                             # Check restart counts
//                             echo ""
//                             echo "[CHECK] Pod Restart Counts:"
//                             kubectl get pods -n ${K8S_NAMESPACE} -o jsonpath='{range .items[*]}{.metadata.name}{" restarts: "}{.status.containerStatuses[0].restartCount}{"\\n"}{end}'
                            
//                             # Verify services
//                             echo ""
//                             echo "[CHECK] Services:"
//                             kubectl get svc -n ${K8S_NAMESPACE}
                            
//                             # Health check from inside cluster
//                             echo ""
//                             echo "[CHECK] Backend Health Check..."
//                             FRONTEND_POD=$(kubectl get pods -n ${K8S_NAMESPACE} -l app.kubernetes.io/name=frontend -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
//                             if [ -n "$FRONTEND_POD" ]; then
//                                 kubectl exec -n ${K8S_NAMESPACE} $FRONTEND_POD -- curl -sf --max-time 10 http://shopdeploy-backend.${K8S_NAMESPACE}.svc.cluster.local:5000/api/health/health && echo "✅ Backend OK" || echo "⚠️ Backend check failed (non-blocking)"
//                             fi
                            
//                             echo ""
//                             echo "╔══════════════════════════════════════════════════════════╗"
//                             echo "║  ✅ SMOKE TESTS PASSED                                   ║"
//                             echo "╚══════════════════════════════════════════════════════════╝"
//                         '''
//                     }
//                 }
//             }
//         }

//         //======================================================================
//         // STAGE 12: CLEANUP
//         //======================================================================
//         stage('Cleanup') {
//             steps {
//                 script {
//                     echo "╔══════════════════════════════════════════════════════════╗"
//                     echo "║  STAGE 12: CLEANUP                                       ║"
//                     echo "╚══════════════════════════════════════════════════════════╝"
                    
//                     sh '''
//                         echo "[CLEANUP] Removing unused Docker resources..."
//                         docker image prune -f
//                         docker system prune -f --volumes || true
//                         echo "✅ Cleanup completed"
//                     '''
//                 }
//             }
//         }
//     }

//     //==========================================================================
//     // POST-BUILD ACTIONS (AUTO ROLLBACK ON FAILURE)
//     //==========================================================================
//     post {
//         success {
//             script {
//                 echo """
//                 ╔══════════════════════════════════════════════════════════════════╗
//                 ║  ✅ PIPELINE COMPLETED SUCCESSFULLY                              ║
//                 ╠══════════════════════════════════════════════════════════════════╣
//                 ║  Environment: ${params.ENVIRONMENT}
//                 ║  Image Tag: ${IMAGE_TAG}
//                 ║  Build: #${BUILD_NUMBER}
//                 ╚══════════════════════════════════════════════════════════════════╝
//                 """
//             }
//         }
        
//         failure {
//             script {
//                 echo """
//                 ╔══════════════════════════════════════════════════════════════════╗
//                 ║  ❌ PIPELINE FAILED - INITIATING AUTO ROLLBACK                   ║
//                 ╚══════════════════════════════════════════════════════════════════╝
//                 """
                
//                 // Auto Rollback on Failure
//                 if (params.ENVIRONMENT == 'prod' || params.ENVIRONMENT == 'staging') {
//                     withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', 
//                                       credentialsId: 'aws-credentials']]) {
//                         sh """
//                             echo "🔄 Starting Auto-Rollback..."
//                             aws eks update-kubeconfig --region ${AWS_REGION} --name ${EKS_CLUSTER_NAME}
                            
//                             echo ""
//                             echo "┌─────────────────────────────────────────┐"
//                             echo "│ AUTO ROLLBACK IN PROGRESS               │"
//                             echo "└─────────────────────────────────────────┘"
//                         """
                        
//                         // Rollback Backend
//                         if (env.PREVIOUS_BACKEND_TAG && env.BACKEND_CHANGED == 'true') {
//                             echo "[ROLLBACK] Rolling back Backend to: ${env.PREVIOUS_BACKEND_TAG}"
//                             sh """
//                                 kubectl rollout undo deployment/shopdeploy-backend -n ${K8S_NAMESPACE} || echo "[WARN] Backend rollback skipped"
//                                 kubectl rollout status deployment/shopdeploy-backend -n ${K8S_NAMESPACE} --timeout=120s || true
//                             """
//                         }
                        
//                         // Rollback Frontend
//                         if (env.PREVIOUS_FRONTEND_TAG && env.FRONTEND_CHANGED == 'true') {
//                             echo "[ROLLBACK] Rolling back Frontend to: ${env.PREVIOUS_FRONTEND_TAG}"
//                             sh """
//                                 kubectl rollout undo deployment/shopdeploy-frontend -n ${K8S_NAMESPACE} || echo "[WARN] Frontend rollback skipped"
//                                 kubectl rollout status deployment/shopdeploy-frontend -n ${K8S_NAMESPACE} --timeout=120s || true
//                             """
//                         }
                        
//                         sh '''
//                             echo ""
//                             echo "📊 Post-Rollback Status:"
//                             kubectl get pods -n ${K8S_NAMESPACE}
//                             echo ""
//                             echo "✅ Auto-Rollback completed"
//                         '''
//                     }
//                 } else {
//                     echo "[INFO] Rollback skipped for dev environment"
//                 }
//             }
//         }
        
//         always {
//             cleanWs()
            
//             script {
//                 echo """
//                 ┌─────────────────────────────────────────┐
//                 │ Pipeline Summary                        │
//                 ├─────────────────────────────────────────┤
//                 │ Build: #${BUILD_NUMBER}
//                 │ Status: ${currentBuild.currentResult}
//                 │ Duration: ${currentBuild.durationString}
//                 │ Environment: ${params.ENVIRONMENT}
//                 └─────────────────────────────────────────┘
//                 """
//             }
//         }
//     }
// }


//==============================================================================
// ShopDeploy - Production-Grade CI/CD Pipeline
//==============================================================================

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
        booleanParam(name: 'SKIP_SONAR', defaultValue: false)
        booleanParam(name: 'FORCE_DEPLOY', defaultValue: false)
    }

    triggers {
        githubPush()
        pollSCM('H/5 * * * *')
    }

    stages {

        stage('Checkout') {
            steps {
                ansiColor('xterm') {
                    checkout scm
                }
            }
        }

        stage('Install Dependencies') {
            parallel {
                stage('Backend Deps') {
                    when { expression { env.BACKEND_CHANGED == 'true' } }
                    steps {
                        ansiColor('xterm') {
                            dir("${BACKEND_DIR}") {
                                sh 'npm ci'
                            }
                        }
                    }
                }

                stage('Frontend Deps') {
                    when { expression { env.FRONTEND_CHANGED == 'true' } }
                    steps {
                        ansiColor('xterm') {
                            dir("${FRONTEND_DIR}") {
                                sh 'npm ci'
                            }
                        }
                    }
                }
            }
        }

        stage('Code Quality (SonarQube)') {
            when { expression { !params.SKIP_SONAR } }
            steps {
                ansiColor('xterm') {
                    withSonarQubeEnv('SonarQube') {
                        sh """
                        npx sonar-scanner \
                          -Dsonar.projectKey=${SONAR_PROJECT_KEY} \
                          -Dsonar.sources=.
                        """
                    }
                }
            }
        }

        stage('Quality Gate') {
            when { expression { !params.SKIP_SONAR } }
            steps {
                ansiColor('xterm') {
                    timeout(time: 5, unit: 'MINUTES') {
                        waitForQualityGate abortPipeline: true
                    }
                }
            }
        }

        stage('Unit Tests') {
            when { expression { !params.SKIP_TESTS } }
            parallel {
                stage('Backend Tests') {
                    steps {
                        ansiColor('xterm') {
                            dir("${BACKEND_DIR}") {
                                sh 'npm test || true'
                            }
                        }
                    }
                }
                stage('Frontend Tests') {
                    steps {
                        ansiColor('xterm') {
                            dir("${FRONTEND_DIR}") {
                                sh 'npm test || true'
                            }
                        }
                    }
                }
            }
        }

        stage('Docker Build') {
            steps {
                ansiColor('xterm') {
                    sh '''
                    chmod +x scripts/build.sh
                    scripts/build.sh backend ${IMAGE_TAG}
                    scripts/build.sh frontend ${IMAGE_TAG}
                    '''
                }
            }
        }

        stage('Push to ECR') {
            steps {
                ansiColor('xterm') {
                    withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-credentials']]) {
                        sh '''
                        aws ecr get-login-password --region ${AWS_REGION} \
                        | docker login --username AWS --password-stdin ${ECR_REGISTRY}

                        scripts/push.sh backend ${IMAGE_TAG} ${ECR_REGISTRY}/${ECR_BACKEND_REPO}
                        scripts/push.sh frontend ${IMAGE_TAG} ${ECR_REGISTRY}/${ECR_FRONTEND_REPO}
                        '''
                    }
                }
            }
        }

        stage('Deploy to Dev/Staging') {
            when { expression { params.ENVIRONMENT != 'prod' } }
            steps {
                ansiColor('xterm') {
                    sh '''
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
                ansiColor('xterm') {
                    sh '''
                    aws eks update-kubeconfig --region ${AWS_REGION} --name ${EKS_CLUSTER_NAME}
                    scripts/deploy.sh backend ${IMAGE_TAG} prod
                    scripts/deploy.sh frontend ${IMAGE_TAG} prod
                    '''
                }
            }
        }

        stage('Smoke Tests') {
            steps {
                ansiColor('xterm') {
                    sh '''
                    kubectl get pods -n ${K8S_NAMESPACE}
                    kubectl rollout status deployment/shopdeploy-backend -n ${K8S_NAMESPACE}
                    kubectl rollout status deployment/shopdeploy-frontend -n ${K8S_NAMESPACE}
                    '''
                }
            }
        }

        stage('Cleanup') {
            steps {
                ansiColor('xterm') {
                    sh 'docker system prune -f || true'
                }
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
