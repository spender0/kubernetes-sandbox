#!/bin/bash

#exit if any command fails
set -e

#exit if /conf/kubelet-bootstrap.conf is not created yet
ls /conf/kubelet-bootstrap.conf

#remove docker pid and sock files left from the previous runs
rm -f /var/run/docker.pid /var/run/docker.sock
service docker start
#wait 15 sec for dockerd
for i in {1..15}
do
   docker ps && break
   sleep 1
done
#exit if docker ps fails
docker ps

pids=()

#run kube-proxy in background
#see full list of options
#https://kubernetes.io/docs/reference/command-line-tools-reference/kube-proxy/
#and https://github.com/kubernetes/kube-proxy/blob/master/config/v1alpha1/types.go
exec kube-proxy \
  --kubeconfig=/conf/kube-proxy.conf \
  --cluster-cidr=10.244.0.0/16 &
pids+=($!)


#run kubelet in background
#see full list of options
#https://kubernetes.io/docs/reference/command-line-tools-reference/kubelet/
#and https://github.com/kubernetes/kubelet/blob/master/config/v1beta1/types.go
#main config
#--config=/conf/kubelet.yaml \
#config with temporary bootstrap token
#--bootstrap-kubeconfig=/conf/kubelet-bootstrap.conf
#this is created by kubelet automatically after bootstrapping
# see #https://kubernetes.io/docs/reference/command-line-tools-reference/kubelet-tls-bootstrapping/
#--kubeconfig=/conf/kubelet.conf
exec kubelet \
  --config=/conf/kubelet.yaml \
  --bootstrap-kubeconfig=/conf/kubelet-bootstrap.conf \
  --kubeconfig=/conf/kubelet.conf \
  --network-plugin=cni &
pids+=($!)

#wait 15 sec for Kubelet's TLS bootstrapping
for i in {1..15}
do
   ls /conf/kubelet.conf && break
   sleep 1
done
#exit if /conf/kubelet.conf is not created
ls /conf/kubelet.conf

#wait for exit status of kubelet and kube-proxy and return it to the script
wait -n $(for p in ${pids[@]}; do echo $p; done)