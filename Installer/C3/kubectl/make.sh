#!/bin/bash
set -e

yum install bash-completion -y
echo "source /usr/share/bash-completion/bash_completion" >>  ~/.bashrc
echo "source <(kubectl completion bash)" >> ~/.bashrc

mkdir /root/.kube
