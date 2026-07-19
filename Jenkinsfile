pipeline {
    agent any

    environment {
        NODE_ENV  = 'test'
        BUILD_DIR = 'dist'
        APP_NAME  = 'kijanikiosk-payments'
        PKG_VERSION = sh(script: 'node -p "require(\'./package.json\').version"', returnStdout: true).trim()
        GIT_SHORT = sh(script: 'git rev-parse --short HEAD', returnStdout: true).trim()
        ARTIFACT_VERSION = "${PKG_VERSION}-${GIT_SHORT}"
        NEXUS_URL = 'http://nexus:8081/repository/npm-kijanikiosk'
    }

    options {
        timeout(time: 15, unit: 'MINUTES')
        buildDiscarder(logRotator(numToKeepStr: '10'))
        disableConcurrentBuilds()
    }

    stages {
        stage('Build') {
            steps {
                sh 'npm ci'
                sh 'npm run build'
                sh 'test -d ${BUILD_DIR} && ls ${BUILD_DIR} | wc -l'
            }
        }
        stage('Test') {
            steps {
                sh 'set -e && npm test'
            }
            post {
                always {
                    junit allowEmptyResults: true, testResults: '**/junit.xml'
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
                        # Generate NEXUS_TOKEN from NEXUS_USER and NEXUS_PASS
                        NEXUS_TOKEN=$(echo -n "${NEXUS_USER}:${NEXUS_PASS}" | base64)
                        # Write .npmrc with registry URL and auth token
                        cat << EOF > .npmrc
registry=http://nexus:8081/repository/npm-kijanikiosk/
//nexus:8081/repository/npm-kijanikiosk/:_auth=\${NEXUS_TOKEN}
EOF
                        # Update package.json version to ARTIFACT_VERSION
                        npm version ${ARTIFACT_VERSION} --no-git-tag-version --allow-same-version
                        # Run npm publish
                        npm publish
                        # Use trap to ensure .npmrc is deleted even if publish fails:
                        trap "rm -f .npmrc" EXIT
                    '''
                }
            }
        }
    }

    post {
        success {
            echo "Published ${env.APP_NAME} version ${env.ARTIFACT_VERSION} to Nexus"
            echo "Artifact URL: ${env.NEXUS_URL}/kijanikiosk-payments/-/kijanikiosk-payments-${env.ARTIFACT_VERSION}.tgz"
        }
        failure {
            echo "Pipeline FAILED: ${env.APP_NAME} build ${env.BUILD_NUMBER} - check logs"
        }
        always {
            deleteDir()
        }
    }
}
