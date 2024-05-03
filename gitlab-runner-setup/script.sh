#!/bin/bash

## check run as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root"
    exit 1
fi

## create gitlab-runner user
useradd --comment "Gitlab Runner" --create-home gitlab-runner --shell /bin/bash
usermod -aG docker gitlab-runner

## install gitlab runner package/binary file, refer to: https://docs.gitlab.com/runner/install/linux-repository.html
# apt-get update && apt-get install dpkg-sig
# curl -JLO "https://packages.gitlab.com/runner/gitlab-runner/gpgkey/runner-gitlab-runner-49F16C5CC3A0F81F.pub.gpg"
# gpg --import runner-gitlab-runner-49F16C5CC3A0F81F.pub.gpg
# curl -L "https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.deb.sh" | sudo bash
# dpkg-sig --verify gitlab-runner_amd64.deb
# sudo apt-get install gitlab-runner

curl -L "https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.rpm.sh" | sudo bash
sudo yum install gitlab-runner

## setup gitlab runner service
tee /etc/systemd/system/gitlab-runner.service >/dev/null <<EOF
[Unit]
Description=GitLab Runner
ConditionFileIsExecutable=/usr/local/bin/gitlab-runner
After=syslog.target network.target

[Service]
StartLimitInterval=5
StartLimitBurst=10
ExecStart=/usr/local/bin/gitlab-runner "run" "--config" "/etc/gitlab-runner/config.toml" "--service" "gitlab-runner"
User=gitlab-runner
EnvironmentFile=-/etc/sysconfig/gitlab-runner
WorkingDirectory=/home/gitlab-runner

Restart=always
RestartSec=120

[Install]
WantedBy=multi-user.target
EOF

## register to gitlab
gitlab-runner register --non-interactive --url "https://gitlab.domain" --token "TOKEN" --executor "shell" --description "Gitlab-Runner" --tag-list "tag" --run-untagger="true" --locked="false" --access-level="not_protected"

## manual register
tee /etc/gitlab-runner/config.toml <<EOF
concurrent = 2
check_interval = 0
connection_max_age = "0"
shutdown_timeout = 0

[session_server]
  session_timeout = 3600

[[runners]]
  name = "runner_name"
  url = "https://gitlab.domain"
  id = 674
  token = "TOKEN"
  token_obtained_at = 2024-03-06T02:17:58Z
  token_expires_at = 0001-01-01T00:00:00Z
  executor = "shell"
  output_limit = 10240
  [runners.cache]
    MaxUploadedArchiveSize = 0
EOF

## enable & start gitlab
systemctl enable gitlab-runner
systemctl start gitlab-runner
