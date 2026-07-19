pipeline {
    agent {
        docker {
            image 'node:18-alpine'
            args  '-v /home/maverick/kijanikiosk-devops:/home/maverick/kijanikiosk-devops --network jenkins-docker_default'
            customWorkspace '/home/maverick/kijanikiosk-devops/workspace/kijanikiosk-payments'
        }
    }

    environment {
        NODE_ENV         = 'test'
        BUILD_DIR        = 'dist'
        APP_NAME         = 'kijanikiosk-payments'
        PKG_VERSION      = sh(script: 'node -p "require(\'./package.json\').version"', returnStdout: true).trim()
        GIT_SHORT        = sh(script: 'echo $GIT_COMMIT | cut -c1-7', returnStdout: true).trim()
        ARTIFACT_VERSION = "${PKG_VERSION}-${GIT_SHORT}"
        NEXUS_URL        = 'http://nexus:8081/repository/npm-kijanikiosk'
    }

    options {
        timeout(time: 15, unit: 'MINUTES')
        buildDiscarder(logRotator(numToKeepStr: '10'))
        disableConcurrentBuilds()
    }

    stages {
        stage('Lint') {
            steps {
                sh 'node -c index.js test.js'
            }
        }

        stage('Build') {
            steps {
                sh 'npm ci'
                sh 'npm run build'
                sh 'test -d ${BUILD_DIR} && ls ${BUILD_DIR} | wc -l'
                stash name: 'build-output', includes: "${BUILD_DIR}/**/*"
            }
        }

        stage('Verify') {
            parallel {
                stage('Test') {
                    steps {
                        unstash 'build-output'
                        sh 'set -e && npm test'
                    }
                    post {
                        always {
                            junit allowEmptyResults: true, testResults: '**/junit.xml'
                        }
                    }
                }
                stage('Security Audit') {
                    steps {
                        sh 'npm audit --audit-level=high || true'
                    }
                }
            }
        }

        stage('Archive') {
            steps {
                archiveArtifacts artifacts: "${BUILD_DIR}/**/*", fingerprint: true
            }
        }

        stage('Publish') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'nexus-credentials',
                    usernameVariable: 'NEXUS_USER',
                    passwordVariable: 'NEXUS_PASS'
                )]) {
                    sh '''
                        set -e
                        # Generate base64 token from NEXUS_USER:NEXUS_PASS
                        NEXUS_TOKEN=$(echo -n "${NEXUS_USER}:${NEXUS_PASS}" | base64)
                        # Write .npmrc with registry and auth token
                        cat << EOF > .npmrc
registry=http://nexus:8081/repository/npm-kijanikiosk/
//nexus:8081/repository/npm-kijanikiosk/:_auth=\${NEXUS_TOKEN}
EOF
                        # Update package version to ARTIFACT_VERSION
                        npm version ${ARTIFACT_VERSION} --no-git-tag-version --allow-same-version
                        # Use trap to ensure .npmrc is removed even if publish fails:
                        trap "rm -f .npmrc" EXIT
                        # npm publish
                        npm publish
                    '''
                }
            }
        }
    }

    post {
        success {
            echo "Successfully built and published version ${env.ARTIFACT_VERSION} to Nexus"
            echo "Artifact URL: ${env.NEXUS_URL}/kijanikiosk-payments/-/kijanikiosk-payments-${env.ARTIFACT_VERSION}.tgz"
        }
        failure {
            echo "Pipeline FAILED: ${env.APP_NAME} build ${env.BUILD_NUMBER}. Please check logs at: ${env.BUILD_URL}"
        }
        changed {
            echo "Build status changed to ${currentBuild.currentResult} - ${env.JOB_NAME} #${env.BUILD_NUMBER}"
        }
        always {
            cleanWs()
        }
    }
}
