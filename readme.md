I created this image for running my acceptance tests on my PHP Yii1 web application project's gitlab-ci, and so you can use it whenever you need to use a docker image containing docker-compose and python3 installed within it.

As you can see above, I use a key file, stored at my `~/.ssh` directory, for ssh access to my-project's git repository.

Example of a `.gitlab-ci.yml` file for Yii1 acceptance tests:
```
image: georgezim85/dind-with-docker-compose:lastest

variables:
  DOCKER_DRIVER: overlay2
  DOCKER_TLS_CERTDIR: ""

services:
  - docker:19.03.1-dind

cache:
  key: ${CI_COMMIT_REF_SLUG}
  paths:
    - image_cache/

before_script:
  - echo "Data local do servidor " && date
  - eval $(ssh-agent -s)
  - echo "$SSH_PRIVATE_KEY" | ssh-add -
  - mkdir -p ~/.ssh
  - chmod 700 ~/.ssh
  - echo "$SSH_KNOWN_HOSTS" > ~/.ssh/known_hosts
  - chmod 644 ~/.ssh/known_hosts
  - docker info
  - docker-compose -v
  - export COMPOSE_INTERACTIVE_NO_CLI=1
  - export COMPOSE_FILE=docker-compose.yml
  - export COMPOSE_PROJECT_NAME=my-image
  - docker volume rm my-image_data || echo -e "  \e[32mNo volume found for to remove"
  - echo "Clonning branch $BRANCHNAME"
  - git clone --single-branch --branch $BRANCHNAME ssh://git@<GITLAB_SERVER_IP>:<SSH_PORT>/my-project.git
  - cd my-project && git log -n 1 && cd ..
  - mkdir -p image_cache/
  - export MAIN_IMAGE="ubuntu:16.04"
  - export MAIN_IMAGE_FILE="image_cache/ubuntu.tar"
  - export SUB_IMAGE="my-image"
  - export SUB_IMAGE_FILE="image_cache/my-image.tar"
  - export MYSQL_IMAGE="mysql:5.6"
  - export MYSQL_IMAGE_FILE="image_cache/mysql.tar"
  - export SELENIUM_IMAGE="selenium/standalone-chrome-debug:latest"
  - export SELENIUM_IMAGE_FILE="image_cache/selenium.tar"
  - docker pull $MAIN_IMAGE
  - docker pull $MYSQL_IMAGE
  - docker pull $SELENIUM_IMAGE
  - docker-compose build my-image
  - docker save $MAIN_IMAGE > $MAIN_IMAGE_FILE
  - docker save $SUB_IMAGE > $SUB_IMAGE_FILE
  - docker save $SELENIUM_IMAGE > $SELENIUM_IMAGE_FILE
  - docker save $MYSQL_IMAGE > $MYSQL_IMAGE_FILE

stages:
  - test

test:
  stage: test
  only:
    variables:
      - $BRANCHNAME
  artifacts:
    when: on_failure
    expire_in: 1 week
    paths:
    - my-project/protected/tests/_output
    - my-project/protected/runtime/application.log
  script:
    - '[ -f "$MAIN_IMAGE_FILE" ] && docker load -i "$MAIN_IMAGE_FILE"'
    - '[ -f "$SUB_IMAGE_FILE" ] && docker load -i "$SUB_IMAGE_FILE"'
    - '[ -f "$SELENIUM_IMAGE_FILE" ] && docker load -i "$SELENIUM_IMAGE_FILE"'
    - '[ -f "$MYSQL_IMAGE_FILE" ] && docker load -i "$MYSQL_IMAGE_FILE"'
    - cp sample.env .env
    - docker-compose up -d db
    - docker-compose up -d selenium
    - docker-compose up -d my-image
    - sleep 20
    - docker-compose logs my-image
    - docker ps
    - docker-compose exec -T -e 'DB_PREFIX=testing_' -e 'ENVIRONMENT=TEST' my-image /build_tests.sh
    - docker-compose exec -T -e 'DB_PREFIX=testing_' -e 'ENVIRONMENT=TEST' my-image sh -c 'cd /my-project && bin/codecept run'

```
