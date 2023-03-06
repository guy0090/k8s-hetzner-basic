#!/bin/bash
TOKEN=$(kubeadm token create --print-join-command)
echo "$TOKEN --cri-socket unix:///run/cri-dockerd.sock"