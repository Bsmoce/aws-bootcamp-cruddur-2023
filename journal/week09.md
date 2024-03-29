# Week 9 — CI/CD with CodePipeline, CodeBuild and CodeDeploy

## Setting up Code Pipeline

1. We create an AWS CodePipeline and choose "GitHub (version 2)" as the source.
2. We skip setting up the Build stage for now.
3. We create the pipeline and then go to the pipeline's settings and we select "Edit".
4. We add a new stage called "build".
5. In the "build" stage, we add action for the CodeBuild project that we created separately which will build our Docker image.
6. After the "build" stage, we add any additional stages you need for deployment, such as "Deploy to Production".
7. We save the changes to our pipeline and test it to ensure that it works correctly.

we add `backend-flask/buildspec.yml`:

```yml
# Buildspec runs in the build stage of your pipeline.
version: 0.2
phases:
  install:
    runtime-versions:
      docker: 20
    commands:
      - echo "cd into $CODEBUILD_SRC_DIR/backend"
      - cd $CODEBUILD_SRC_DIR/backend-flask
      - aws ecr get-login-password --region $AWS_DEFAULT_REGION | docker login --username AWS --password-stdin $IMAGE_URL
  build:
    commands:
      - echo Build started on `date`
      - echo Building the Docker image...          
      - docker build -t backend-flask .
      - docker tag $REPO_NAME $IMAGE_URL/$REPO_NAME
  post_build:
    commands:
      - echo Build completed on `date`
      - echo Pushing the Docker image..
      - docker push $IMAGE_URL/$REPO_NAME
      - cd $CODEBUILD_SRC_DIR
      - echo "imagedefinitions.json > [{\"name\":\"$CONTAINER_NAME\",\"imageUri\":\"$IMAGE_URL/$REPO_NAME\"}]" > imagedefinitions.json
      - printf "[{\"name\":\"$CONTAINER_NAME\",\"imageUri\":\"$IMAGE_URL/$REPO_NAME\"}]" > imagedefinitions.json

env:
  variables:
    AWS_ACCOUNT_ID: 354592008288
    AWS_DEFAULT_REGION: ca-central-1
    CONTAINER_NAME: backend-flask
    IMAGE_URL: 354592008288.dkr.ecr.ca-central-1.amazonaws.com
    REPO_NAME: backend-flask:latest
artifacts:
  files:
    - imagedefinitions.json
```

## Merge two branches

We merged main branch into prod branch to trigger CodePipeline

![CICD](assets/Week09-CICD.png)<br>