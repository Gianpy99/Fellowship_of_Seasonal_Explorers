// =============================================================================
// Jenkinsfile - Seasonal Explorers on the Family Portal (build + deploy on the Pi)
// Based on FamilyPortal/templates/new-app/Jenkinsfile.
// Flow: tests -> docker build -> replace container -> health check
//       -> automatic rollback to the previous image if the health check fails.
// =============================================================================
pipeline {
    agent any

    options {
        disableConcurrentBuilds()
        buildDiscarder(logRotator(numToKeepStr: '10'))
        timeout(time: 30, unit: 'MINUTES')
    }

    triggers {
        // No webhook (GitHub cannot reach Jenkins): poll every ~3 minutes.
        pollSCM('H/3 * * * *')
    }

    environment {
        APP_ID         = 'seasonal-quest'
        IMAGE          = "${APP_ID}:latest"
        IMAGE_PREVIOUS = "${APP_ID}:previous"
        CONTAINER      = "${APP_ID}"
        HOST_PORT      = '8096'
        CONTAINER_PORT = '8080'
        HEALTH_PATH    = '/health'
        DATA_VOL       = "${APP_ID}-data"
        PUBLIC_URL     = 'https://seasons.borrellofamily.co.uk/'
    }

    stages {
        stage('Test') {
            steps {
                sh 'docker build --target test -t $APP_ID:test .'
            }
        }

        stage('Build image') {
            steps {
                sh '''
                    if docker image inspect $IMAGE >/dev/null 2>&1; then
                        docker tag $IMAGE $IMAGE_PREVIOUS
                    fi
                    docker build -t $IMAGE .
                '''
            }
        }

        stage('Deploy + health check') {
            steps {
                withCredentials([
                    string(credentialsId: 'seasonal-quest-gemini-api-key', variable: 'GEMINI_API_KEY'),
                ]) {
                    sh '''
                        run_app() {
                            docker rm -f $CONTAINER >/dev/null 2>&1 || true
                            docker run -d \
                                --name $CONTAINER \
                                --restart unless-stopped \
                                -p 127.0.0.1:$HOST_PORT:$CONTAINER_PORT \
                                -e APP_ENV=production \
                                -e GEMINI_API_KEY="$GEMINI_API_KEY" \
                                -e AI_IMAGES_PER_DAY=40 \
                                -e AI_TEXT_PER_DAY=300 \
                                -v $DATA_VOL:/app/data \
                                "$1"
                        }

                        # Probes the app from inside its own network namespace, so
                        # the app image does not need curl/wget installed.
                        healthy() {
                            for i in $(seq 1 20); do
                                if docker run --rm --network container:$CONTAINER curlimages/curl:latest \
                                       -fsS -o /dev/null --max-time 5 "http://localhost:$CONTAINER_PORT$HEALTH_PATH"; then
                                    return 0
                                fi
                                sleep 3
                            done
                            return 1
                        }

                        docker volume create $DATA_VOL >/dev/null
                        run_app $IMAGE
                        if healthy; then
                            echo "$APP_ID is healthy"
                            exit 0
                        fi

                        echo "Health check FAILED. Last logs:"
                        docker logs --tail 100 $CONTAINER || true
                        if docker image inspect $IMAGE_PREVIOUS >/dev/null 2>&1; then
                            echo "Rolling back to $IMAGE_PREVIOUS"
                            run_app $IMAGE_PREVIOUS
                            healthy && echo "Rollback OK" || echo "Rollback is ALSO unhealthy"
                        fi
                        exit 1
                    '''
                }
            }
        }
    }

    post {
        success {
            echo "Deployed: ${PUBLIC_URL}"
        }
        failure {
            echo "Deploy FAILED. Logs: docker logs ${CONTAINER}"
        }
        always {
            sh 'docker image prune -f >/dev/null 2>&1 || true'
        }
    }
}
