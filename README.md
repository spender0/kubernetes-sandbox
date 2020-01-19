### Kubernetes sandbox
#### Yet another local Kubernetes
![alt text](https://github.com/spender0/kubernetes-sandbox/raw/master/kubernetes-sandbox.jpg)
 
#### Motivation
For ones who need to understand Kubernetes's complex architecture.

Such tools as minikube or kubeadm encapsulates the complexity.
As a result you get working kubernates without understanding how the things are done.

It is just well-commented code. I believe that well-commented code examples are much better than tons of instructions.

#### Features:
* SSL certificates and requirements with using old good openssl tool
* Fully automated and dockerized, only docker and docker-compose required
* All settings are transparent, you can fully control the cluster
* New convenient feature is implemented https://kubernetes.io/docs/reference/access-authn-authz/bootstrap-tokens

#### Requirements:
sudo  sh -c 'echo "net.bridge.bridge-nf-call-iptables=1" >> /etc/sysctl.conf; sysctl -p'

* Docker https://docs.docker.com/install/
* Docker-compose https://docs.docker.com/compose/install/
* Git https://git-scm.com/downloads

#### Run:

```
git clone https://github.com/spender0/kubernetes-sandbox.git

cd kubernetes-sandbox

docker-compose up -d
```

kubectl is available either via docker:

`docker exec -it kubernetes-sandbox_kubeadm_1 bash`

or you can install it https://kubernetes.io/docs/tasks/tools/install-kubectl/

and then run:

```
export KUBECONFIG=conf/admin-local.conf

kubectl -n kube-system get pods
``` 

#### Stop:
```
docker-compose down
```

#### Remove completely:
```
docker-compose down

git reset --hard
```

#### References
Based on: https://kubernetes.io/docs/reference/

Docker images: https://console.cloud.google.com/gcr/images/google-containers/GLOBAL
