[
  {
    "name": "${CONTAINER_NAME}",
    "image": "${REPOSITORY_URL}:latest",
    "essential": true,
    "environment": [
      {
          "name": "environment",
          "value": "${ENV_VAR}"
      }
    ],
    "portMappings": [
      {
        "containerPort": 3000
      }
    ],
    "memory": 512,
    "cpu": 256
  }
]