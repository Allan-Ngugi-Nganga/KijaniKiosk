pipeline{
    agent any

    tools {
        nodejs 'Node20' 
    }
    
    stages{
        stage('Environment Check'){
            steps {
                sh 'echo "Build triggered for : $(git log -1 --pretty=%s)"'
                sh 'node --version'
                sh 'npm --version'
            }
        }
    }

    post {
        always{
            echo "Pipeline finished. Status: ${currentBuild.result ?: 'SUCCESS'}"
        }
    }
}
