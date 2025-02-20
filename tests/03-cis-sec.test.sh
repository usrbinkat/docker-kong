#!/usr/bin/env bash

function run_test {
  # the suite name below will only be used when rtunning this file directly, when
  # running through "test.sh" it must be provided using the "--suite" option.
  tinitialize "Docker-Kong test suite" "${BASH_SOURCE[0]}"

  tchapter "CIS-Sec tests $KONG_DOCKER_TAG"
  ttest "CIS-Sec for docker-compose"

  pushd compose
    docker-compose stop
    KONG_INBOUND_PROXY_LISTEN=127.0.0.1 KONG_INBOUND_SSL_PROXY_LISTEN=127.0.0.1 docker-compose up -d
    until docker-compose ps | grep compose_kong_1 | grep -q "Up"; do sleep 1; done
  popd

  rm -rf tests/docker-bench-security

  LOG_OUTPUT=docker-bench-security.log

  # * 5.1 is "apparmor". That option is not available in docker compose 3.x
  # * 5.10 is "mem_limit". That option is not available in docker compose 3.x (it has moved to resources)
  # * 5.11 is "cpu_shares". That option is not available in docker compose 3.x
  # * 5.28 is "pids_limit". That option is also not available in docker compose 3.x
  # * See https://github.com/docker/compose/issues/4513 for more examples of incompatibilities
  LINUX_EXCLUDE_TESTS=5_1,5_10,5_11,5_28

  if [[ -f /lib/systemd/system/docker.service ]]; then # Ubuntu
    mkdir tests/docker-bench-security
    pushd tests/docker-bench-security
    docker run --rm --net host --pid host --userns host --cap-add audit_control \
      -e DOCKER_CONTENT_TRUST=$DOCKER_CONTENT_TRUST \
      -v /etc:/etc:ro \
      -v /lib/systemd/system:/lib/systemd/system:ro \
      -v /usr/bin/containerd:/usr/bin/containerd:ro \
      -v /usr/bin/runc:/usr/bin/runc:ro \
      -v /usr/lib/systemd:/usr/lib/systemd:ro \
      -v /var/lib:/var/lib:ro \
      -v /var/run/docker.sock:/var/run/docker.sock:ro \
      --label docker_bench_security \
      docker/docker-bench-security -e $LINUX_EXCLUDE_TESTS > $LOG_OUTPUT

  else # all other linux distros
    mkdir tests/docker-bench-security
    pushd tests/docker-bench-security
    docker run --rm --net host --pid host --userns host --cap-add audit_control \
      -e DOCKER_CONTENT_TRUST=$DOCKER_CONTENT_TRUST \
      -v /etc:/etc:ro \
      -v /usr/bin/containerd:/usr/bin/containerd:ro \
      -v /usr/bin/runc:/usr/bin/runc:ro \
      -v /usr/lib/systemd:/usr/lib/systemd:ro \
      -v /var/lib:/var/lib:ro \
      -v /var/run/docker.sock:/var/run/docker.sock:ro \
      --label docker_bench_security \
      docker/docker-bench-security -e $LINUX_EXCLUDE_TESTS > $LOG_OUTPUT
  fi

  if cat "$LOG_OUTPUT" | grep WARN | grep kong -B 1; then
    tmessage "Found warnings in docker-bench-security report"
    tfailure
  else
    tsuccess
  fi

  popd
  rm -rf tests/docker-bench-security

  tfinish
}

# No need to modify anything below this comment

# shellcheck disable=SC1090  # do not follow source
[[ "$T_PROJECT_NAME" == "" ]] && set -e && source "${1:-$(dirname "$(realpath "$0")")/test.sh}" && set +e
run_test
