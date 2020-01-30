#!/bin/bash
#based on https://kubernetes.io/docs/setup/certificates/

#exit if any command fails
set -e

#let's assume it is your company root CA:
openssl req -nodes -subj "/C=US/ST=None/L=None/O=None/CN=example.com" -new -x509 -days 9999  -keyout certs/company-root-ca.key -out certs/company-root-ca.crt

#but you'd better not reveal your root CA with creating
#intermediate certificates specially for kubernetes related stuff

#generate intermediate etcd-ca:
mkdir -p certs/etcd
openssl genrsa -out certs/etcd/ca.key 4096
openssl req -new -nodes -sha256 -subj "/C=US/ST=None/L=None/O=None/CN=etcd-ca"  -key certs/etcd/ca.key -out certs/etcd/ca.csr
openssl x509 -req -days 9999  -sha256 -CA certs/company-root-ca.crt -CAkey certs/company-root-ca.key -set_serial 01 -extensions req_ext -in certs/etcd/ca.csr -out certs/etcd/ca.crt
cat certs/etcd/ca.crt certs/company-root-ca.crt > certs/etcd/ca-bundle.crt

#generate intermediate kubernetes-ca:
openssl genrsa -out certs/kubernetes-ca.key 4096
openssl req -new -nodes -sha256 -subj "/C=US/ST=None/L=None/O=None/CN=kubernetes-ca"  -key certs/kubernetes-ca.key -out certs/kubernetes-ca.csr
openssl x509 -req -days 9999  -sha256 -CA certs/company-root-ca.crt -CAkey certs/company-root-ca.key -set_serial 02 -extensions req_ext -in certs/kubernetes-ca.csr -out certs/kubernetes-ca.crt
cat certs/kubernetes-ca.crt certs/company-root-ca.crt > certs/kubernetes-ca-bundle.crt

#generate intermediate kubernetes-front-proxy-ca:
openssl genrsa -out certs/front-proxy-ca.key 4096
openssl req -new -nodes -sha256 -subj "/C=US/ST=None/L=None/O=None/CN=kubernetes-ca"  -key certs/front-proxy-ca.key -out certs/front-proxy-ca.csr
openssl x509 -req -days 9999  -sha256 -CA certs/company-root-ca.crt -CAkey certs/company-root-ca.key -set_serial 02 -extensions req_ext -in certs/front-proxy-ca.csr -out certs/front-proxy-ca.crt
cat certs/front-proxy-ca.crt certs/company-root-ca.crt > certs/front-proxy-ca-bundle.crt

#generate and sign etcd server cert:
openssl genrsa -out certs/etcd/server.key 4096
openssl req -new -nodes -sha256 -subj "/C=US/ST=None/L=None/O=None/CN=kube-etcd"  -key certs/etcd/server.key -out certs/etcd/server.csr
openssl x509 -req -days 9999  \
  -extfile <(printf "subjectAltName=DNS:kube-etcd1,DNS:kube-etcd2,DNS:kube-etcd3,DNS:kube-etcd,DNS:localhost") \
  -sha256 -CA certs/etcd/ca.crt -CAkey certs/etcd/ca.key -set_serial 01 -in certs/etcd/server.csr -out certs/etcd/server.crt

#generate and sign etcd peer cert:
openssl genrsa -out certs/etcd/peer.key 4096
openssl req -new -nodes -sha256 -subj "/C=US/ST=None/L=None/O=None/CN=kube-etcd-peer"  -key certs/etcd/peer.key -out certs/etcd/peer.csr
openssl x509 -req -days 9999 \
  -extfile <(printf "subjectAltName=DNS:kube-etcd1,DNS:kube-etcd2,DNS:kube-etcd,DNS:localhost") \
  -sha256 -CA certs/etcd/ca.crt -CAkey certs/etcd/ca.key -set_serial 01 -in certs/etcd/peer.csr -out certs/etcd/peer.crt

#generate and sign kube-etcd-healthcheck-client cert:
openssl genrsa -out certs/etcd/healthcheck-client.key 4096
openssl req -new -nodes -sha256 -subj "/C=US/ST=None/L=None/O=None/CN=kube-etcd-healthcheck-client"  -key certs/etcd/healthcheck-client.key -out certs/etcd/healthcheck-client.csr
openssl x509 -req -days 9999  -sha256 -CA certs/etcd/ca.crt -CAkey certs/etcd/ca.key -set_serial 01 -extensions req_ext -in certs/etcd/healthcheck-client.csr -out certs/etcd/healthcheck-client.crt

#kube-apiserver as a client of etcd:
openssl genrsa -out certs/apiserver-etcd-client.key 4096
openssl req -new -nodes -sha256 -subj "/C=US/ST=None/L=None/O=None/CN=kube-apiserver-etcd-client"  -key certs/apiserver-etcd-client.key -out certs/apiserver-etcd-client.csr
openssl x509 -req -days 9999  -sha256 -CA certs/etcd/ca.crt -CAkey certs/etcd/ca.key -set_serial 01 -extensions req_ext -in certs/apiserver-etcd-client.csr -out certs/apiserver-etcd-client.crt

#kube-apiserver as a server:
openssl genrsa -out certs/kube-apiserver.key 4096
openssl req -new -nodes -sha256 -subj "/C=US/ST=None/L=None/O=None/CN=kube-apiserver" -key certs/kube-apiserver.key -out certs/kube-apiserver.csr
openssl x509 -req -days 9999 \
  -extfile <(printf "subjectAltName=IP:10.1.0.1,IP:127.0.0.1,DNS:kubernetes.default.svc.cluster.local,DNS:kube-apiserver,DNS:localhost") \
  -sha256  -CA certs/kubernetes-ca.crt -CAkey certs/kubernetes-ca.key -set_serial 01  -in certs/kube-apiserver.csr -out certs/kube-apiserver.crt
#cat certs/kube-apiserver.crt certs/kube-apiserver.key > certs/kube-apiserver.pem

#kube-apiserver as a client of kubelet:
#https://kubernetes.io/docs/setup/best-practices/certificates/#all-certificates
openssl genrsa -out certs/apiserver-kubelet-client.key 4096
openssl req -new -nodes -sha256 -subj "/C=US/ST=None/L=None/O=system:masters/CN=kube-apiserver-kubelet-client" -key certs/apiserver-kubelet-client.key -out certs/apiserver-kubelet-client.csr
openssl x509 -req  -days 9999  -sha256 -CA certs/kubernetes-ca.crt -CAkey certs/kubernetes-ca.key -set_serial 01 -extensions req_ext -in certs/apiserver-kubelet-client.csr -out certs/apiserver-kubelet-client.crt

#kubelet as a server:
#https://kubernetes.io/docs/setup/best-practices/certificates/#all-certificates
openssl genrsa -out certs/kubelet.key 4096
openssl req -new -nodes -sha256 -subj "/C=US/ST=None/L=None/O=None/CN=kube-node" -key certs/kubelet.key -out certs/kubelet.csr
openssl x509 -req  -days 9999  -sha256 -CA certs/kubernetes-ca.crt -CAkey certs/kubernetes-ca.key -set_serial 01 -extensions req_ext -in certs/kubelet.csr -out certs/kubelet.crt

#generate certificates for administrator
# "O" and "CN" in the subject is important, see https://kubernetes.io/docs/setup/best-practices/certificates/#configure-certificates-for-user-accounts
openssl genrsa -out certs/admin.key 4096
openssl req -new -nodes -sha256 -subj "/C=US/ST=None/L=None/O=system:masters/CN=kubernetes-admin"  -key certs/admin.key -out certs/admin.csr
openssl x509 -req -days 9999  -sha256 -CA  certs/kubernetes-ca.crt -CAkey  certs/kubernetes-ca.key -set_serial 01 -extensions req_ext -in certs/admin.csr -out certs/admin.crt

#kube-scheduler as a client of apiserver:
openssl genrsa -out certs/kube-scheduler-apiserver-client.key 4096
openssl req -new -nodes -sha256 -subj "/C=US/ST=None/L=None/O=None/CN=system:kube-scheduler"  -key certs/kube-scheduler-apiserver-client.key -out certs/kube-scheduler-apiserver-client.csr
openssl x509 -req -days 9999  -sha256 -CA  certs/kubernetes-ca.crt -CAkey  certs/kubernetes-ca.key -set_serial 01 -extensions req_ext -in certs/kube-scheduler-apiserver-client.csr -out certs/kube-scheduler-apiserver-client.crt

#kube-proxy as a client of apiserver
#"CN" in the subject is important, see https://kubernetes.io/docs/reference/access-authn-authz/rbac/#core-component-roles
openssl genrsa -out certs/kube-proxy-apiserver-client.key 4096
openssl req -new -nodes -sha256 -subj "/C=US/ST=None/L=None/O=None/CN=system:kube-proxy"  -key certs/kube-proxy-apiserver-client.key -out certs/kube-proxy-apiserver-client.csr
openssl x509 -req -days 9999  -sha256 -CA  certs/kubernetes-ca.crt -CAkey  certs/kubernetes-ca.key -set_serial 01 -extensions req_ext -in certs/kube-proxy-apiserver-client.csr -out certs/kube-proxy-apiserver-client.crt

#kube-controller-manager as a client of apiserver:
openssl genrsa -out certs/kube-controller-manager-apiserver-client.key 4096
openssl req -new -nodes -sha256 -subj "/C=US/ST=None/L=None/O=None/CN=system:kube-controller-manager"  -key certs/kube-controller-manager-apiserver-client.key -out certs/kube-controller-manager-apiserver-client.csr
openssl x509 -req -days 9999  -sha256 -CA  certs/kubernetes-ca.crt -CAkey  certs/kubernetes-ca.key -set_serial 01 -extensions req_ext -in certs/kube-controller-manager-apiserver-client.csr -out certs/kube-controller-manager-apiserver-client.crt

#kubelet as a server:
openssl genrsa -out certs/kubelet.key 4096
openssl req -new -nodes -sha256 -subj "/C=US/ST=None/L=None/O=None/CN=kube-node"  -key certs/kubelet.key -out certs/kubelet.csr
openssl x509 -req -days 9999  -sha256 -CA  certs/kubernetes-ca.crt -CAkey  certs/kubernetes-ca.key -set_serial 01 -extensions req_ext -in certs/kubelet.csr -out certs/kubelet.crt

#generate kubeconfig for administrator:
export KUBECONFIG=conf/admin.conf
kubectl config set-cluster default-cluster --server=https://kube-apiserver:6443 --certificate-authority certs/kubernetes-ca-bundle.crt --embed-certs
kubectl config set-credentials default-admin --client-key certs/admin.key --client-certificate certs/admin.crt --embed-certs
kubectl config set-context default-system --cluster default-cluster --user 	default-admin
kubectl config use-context default-system


#generate kubeconfig for administrator (for running kubectl from the host):
export KUBECONFIG=conf/admin-local.conf
kubectl config set-cluster default-cluster --server=https://localhost:6443 --certificate-authority certs/kubernetes-ca-bundle.crt --embed-certs
kubectl config set-credentials default-admin --client-key certs/admin.key --client-certificate certs/admin.crt --embed-certs
kubectl config set-context default-system --cluster default-cluster --user 	default-admin
kubectl config use-context default-system

#generate kubeconfig for kube-scheduler:
export KUBECONFIG=conf/kube-scheduler.conf
kubectl config set-cluster default-cluster --server=https://kube-apiserver:6443 --certificate-authority certs/kubernetes-ca-bundle.crt --embed-certs
kubectl config set-credentials default-manager --client-key certs/kube-scheduler-apiserver-client.key --client-certificate certs/kube-scheduler-apiserver-client.crt --embed-certs
kubectl config set-context default-system --cluster default-cluster --user default-manager
kubectl config use-context default-system

#generate kubeconfig for kube-controller-manager:
export KUBECONFIG=conf/kube-controller-manager.conf
kubectl config set-cluster default-cluster --server=https://kube-apiserver:6443 --certificate-authority certs/kubernetes-ca-bundle.crt --embed-certs
kubectl config set-credentials default-controller-manager --client-key certs/kube-controller-manager-apiserver-client.key --client-certificate certs/kube-controller-manager-apiserver-client.crt --embed-certs
kubectl config set-context default-system --cluster default-cluster --user default-controller-manager
kubectl config use-context default-system

#generate kubeconfig for kube-proxy:
export KUBECONFIG=conf/kube-proxy.conf
kubectl config set-cluster default-cluster --server=https://kube-apiserver:6443 --certificate-authority certs/kubernetes-ca-bundle.crt --embed-certs
kubectl config set-credentials default-kube-proxy --client-key certs/kube-proxy-apiserver-client.key --client-certificate certs/kube-proxy-apiserver-client.crt --embed-certs
kubectl config set-context default-system --cluster default-cluster --user 	default-kube-proxy
kubectl config use-context default-system


chmod  777 certs
chmod -R 666 certs/*
chmod  777 certs/etcd

chmod  777 conf
chmod -R 666 conf/*
