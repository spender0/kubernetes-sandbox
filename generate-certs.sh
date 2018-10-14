#!/bin/bash
#based on https://kubernetes.io/docs/setup/certificates/

set -e

#let's assume it is your company root CA:
openssl req -nodes -subj "/C=US/ST=None/L=None/O=None/CN=example.com" -new -x509 -days 9999  -keyout certs/ca.key -out certs/ca.crt

#but you'd better not reveal your root CA with creating
#intermediate certificates specially for kubernetes related stuff

#generate intermediate etcd-ca:
openssl genrsa -out certs/etcd-ca.key 4096
openssl req -new -nodes -sha256 -subj "/C=US/ST=None/L=None/O=None/CN=etcd-ca"  -key certs/etcd-ca.key -out certs/etcd-ca.csr
openssl x509 -req -days 9999  -sha256 -CA certs/ca.crt -CAkey certs/ca.key -set_serial 01 -extensions req_ext -in certs/etcd-ca.csr -out certs/etcd-ca.crt
cat certs/etcd-ca.crt certs/ca.crt > certs/etcd-ca-bundle.crt

#generate intermediate kubernetes-ca:
openssl genrsa -out certs/kubernetes-ca.key 4096
openssl req -new -nodes -sha256 -subj "/C=US/ST=None/L=None/O=None/CN=kubernetes-ca"  -key certs/kubernetes-ca.key -out certs/kubernetes-ca.csr
openssl x509 -req -days 9999  -sha256 -CA certs/ca.crt -CAkey certs/ca.key -set_serial 02 -extensions req_ext -in certs/kubernetes-ca.csr -out certs/kubernetes-ca.crt
cat certs/kubernetes-ca.crt certs/ca.crt > certs/kubernetes-ca-bundle.crt

#generate and sign etcd-crt:
openssl genrsa -out certs/etcd.key 4096
openssl req -new -nodes -sha256 -subj "/C=US/ST=None/L=None/O=None/CN=etcd"  -key certs/etcd.key -out certs/etcd.csr
openssl x509 -req -days 9999  -sha256 -CA certs/etcd-ca.crt -CAkey certs/etcd-ca.key -set_serial 01 -extensions req_ext -in certs/etcd.csr -out certs/etcd.crt

#kube-apiserver as a client of etcd:
openssl genrsa -out certs/kube-apiserver-etcd.key 4096
openssl req -new -nodes -sha256 -subj "/C=US/ST=None/L=None/O=None/CN=kube-apiserver"  -key certs/kube-apiserver-etcd.key -out certs/kube-apiserver-etcd.csr
openssl x509 -req -days 9999  -sha256 -CA certs/etcd-ca.crt -CAkey certs/etcd-ca.key -set_serial 01 -extensions req_ext -in certs/kube-apiserver-etcd.csr -out certs/kube-apiserver-etcd.crt

#kube-apiserver as a server:
openssl genrsa -out certs/kube-apiserver.key 4096
openssl req -new -nodes -sha256 -subj "/C=US/ST=None/L=None/O=None/CN=kube-apiserver" -key certs/kube-apiserver.key -out certs/kube-apiserver.csr
openssl x509 -req  -days 9999  -sha256 -CA certs/kubernetes-ca.crt -CAkey certs/kubernetes-ca.key -set_serial 01 -extensions req_ext -in certs/kube-apiserver.csr -out certs/kube-apiserver.crt
cat certs/kube-apiserver.crt certs/kube-apiserver.key > certs/kube-apiserver.pem

#kube-scheduler as a client of apiserver:
openssl genrsa -out certs/kube-scheduler-apiserver.key 4096
openssl req -new -nodes -sha256 -subj "/C=US/ST=None/L=None/O=None/CN=system:kube-scheduler"  -key certs/kube-scheduler-apiserver.key -out certs/kube-scheduler-apiserver.csr
openssl x509 -req -days 9999  -sha256 -CA  certs/kubernetes-ca.crt -CAkey  certs/kubernetes-ca.key -set_serial 01 -extensions req_ext -in certs/kube-scheduler-apiserver.csr -out certs/kube-scheduler-apiserver.crt

#kube-proxy as a client of apiserver:
openssl genrsa -out certs/kube-proxy-apiserver.key 4096
openssl req -new -nodes -sha256 -subj "/C=US/ST=None/L=None/O=None/CN=system:kube-proxy"  -key certs/kube-proxy-apiserver.key -out certs/kube-proxy-apiserver.csr
openssl x509 -req -days 9999  -sha256 -CA  certs/kubernetes-ca.crt -CAkey  certs/kubernetes-ca.key -set_serial 01 -extensions req_ext -in certs/kube-proxy-apiserver.csr -out certs/kube-proxy-apiserver.crt

#kube-controller-manager as a client of apiserver:
openssl genrsa -out certs/kube-controller-manager-apiserver.key 4096
openssl req -new -nodes -sha256 -subj "/C=US/ST=None/L=None/O=None/CN=system:kube-controller-manager"  -key certs/kube-controller-manager-apiserver.key -out certs/kube-controller-manager-apiserver.csr
openssl x509 -req -days 9999  -sha256 -CA  certs/kubernetes-ca.crt -CAkey  certs/kubernetes-ca.key -set_serial 01 -extensions req_ext -in certs/kube-controller-manager-apiserver.csr -out certs/kube-controller-manager-apiserver.crt

#kubelet as a client of apiserver:
openssl genrsa -out certs/kubelet-apiserver.key 4096
openssl req -new -nodes -sha256 -subj "/C=US/ST=None/L=None/O=system:nodes/CN=system:node:kubelet"  -key certs/kubelet-apiserver.key -out certs/kubelet-apiserver.csr
openssl x509 -req -days 9999  -sha256 -CA  certs/kubernetes-ca.crt -CAkey  certs/kubernetes-ca.key -set_serial 01 -extensions req_ext -in certs/kubelet-apiserver.csr -out certs/kubelet-apiserver.crt

#kubernetes dashboard as a server
openssl genrsa -out certs/dashboard.key 4096
openssl req -new -nodes -sha256 -subj "/C=US/ST=None/L=None/O=None/CN=dashboard" -key certs/dashboard.key -out certs/dashboard.csr
openssl x509 -req  -days 9999  -sha256 -CA certs/kubernetes-ca.crt -CAkey certs/kubernetes-ca.key -set_serial 01 -extensions req_ext -in certs/dashboard.csr -out certs/dashboard.crt

#generate certificates for administrator:
openssl genrsa -out certs/admin.key 4096
openssl req -new -nodes -sha256 -subj "/C=US/ST=None/L=None/O=system:masters/CN=kubernetes-admin"  -key certs/admin.key -out certs/admin.csr
openssl x509 -req -days 9999  -sha256 -CA  certs/kubernetes-ca.crt -CAkey  certs/kubernetes-ca.key -set_serial 01 -extensions req_ext -in certs/admin.csr -out certs/admin.crt

#generate kubeconfig for kube-scheduler:
export KUBECONFIG=conf/kube-scheduler.conf
kubectl config set-cluster default-cluster --server=https://kube-apiserver:6443 --certificate-authority certs/kubernetes-ca-bundle.crt --embed-certs
kubectl config set-credentials default-manager --client-key certs/kube-scheduler-apiserver.key --client-certificate certs/kube-scheduler-apiserver.crt --embed-certs
kubectl config set-context default-system --cluster default-cluster --user default-manager
kubectl config use-context default-system

#generate kubeconfig for kube-controller-manager:
export KUBECONFIG=conf/kube-controller-manager.conf
kubectl config set-cluster default-cluster --server=https://kube-apiserver:6443 --certificate-authority certs/kubernetes-ca-bundle.crt --embed-certs
kubectl config set-credentials default-controller-manager --client-key certs/kube-controller-manager-apiserver.key --client-certificate certs/kube-controller-manager-apiserver.crt --embed-certs
kubectl config set-context default-system --cluster default-cluster --user default-controller-manager
kubectl config use-context default-system

#generate kubeconfig for administrator:
export KUBECONFIG=conf/admin.conf
kubectl config set-cluster default-cluster --server=https://kube-apiserver:6443 --certificate-authority certs/kubernetes-ca-bundle.crt --embed-certs
kubectl config set-credentials default-admin --client-key certs/admin.key --client-certificate certs/admin.crt --embed-certs
kubectl config set-context default-system --cluster default-cluster --user 	default-admin
kubectl config use-context default-system