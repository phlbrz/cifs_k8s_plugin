# Deprecated

* Use https://blog.openshift.com/mounting-cifs-shares-in-openshift/ 

## Status

~~Tested and working on kubernetes 1.7.x and 1.11.x / Openshift 3.7 and 3.11 ( rhel 7.x ) with SELinux enabled. Needs DC with privileged: true at seLinuxContext.~~

## Build & Package Kubernetes cifs plugin with Dockerception

Provide a Kubernetes cifs for CoreOS/Ubuntu/Fedora.. (for example) to use, optimized for speed.

### Delivering plugin to a docker host

Kubernetes:

```bash
docker run -it --rm -v /etc/kubernetes/volumeplugins/phlbrz~cifs:/target phlbrz/cifs_k8s_plugin /target
```

Openshift:

```bash
docker run -it --rm -v /usr/libexec/kubernetes/kubelet-plugins/volume/exec/phlbrz~cifs:/target phlbrz/cifs_k8s_plugin /target
```

After installing the plugin, restart the kubelet or the origin-node service so that the plugin is detected.

### Important notes

- generated from a fork of -> https://github.com/fvigotti/cifs_k8s_plugin
- getvolumename is not implemented because there is a bug in kube 1.6.x https://github.com/kubernetes/kubernetes/issues/44737
- kubelet flags : 
  - "--volume-plugin-dir=/etc/kubernetes/volumeplugins"
  - "--enable-controller-attach-detach=false"
- controller manager flags:
  - "--flex-volume-plugin-dir=/etc/kubernetes/volumeplugins"

- not sure if it's really true but seems that after the creation of the plugin directory (/etc/kubernetes/volumeplugins/phlbrz)
  kubelet needed a restart, hot-changes to plugin source can be done in place without further restarts

### Sample usage

Assuming a `//192.168.56.101/TEST` cifs share, accessible by a `TESTER` user with a `SECRET` password.

1. create secret to access the cifs share

```sh
kubectl create secret generic cifscreds --from-literal username=TESTER --from-literal password=SECRET
```

2. create the cifs-enabled pod

```sh
cat <<EOF | tee pod.yml
apiVersion: v1
kind: Pod
metadata:
  name: cc
spec:
  containers:
  - name: cc
    image: nginx
    volumeMounts:
    - name: test
      mountPath: /data
    ports:
    - containerPort: 80
  volumes:
  - name: test
    flexVolume:
      driver: "phlbrz/cifs"
      secretRef:
        name: cifscreds
      readOnly: true
      options:
        source: "//192.168.56.101/TEST"
        mountOptions: "dir_mode=0700,file_mode=0600"
EOF
```

generate the secret file, nb: the `type` is mandatory

```sh
cat <<EOF | tee secret.yml
apiVersion: v1
data:
  password: bas64pwd
  username: bas64user
kind: Secret
metadata:
  name: cifscreds
  namespace: default
type: "phlbrz/cifs"
EOF
```

Feel free to edit the flexVolume specification to match your needs.

3. run the pod

```sh
kubectl create -f pod.yml
```

4. verify the pod

```sh
kubectl get pod cc
kubectl exec cc -- df ; ls -l /data
```

5. don't panic  
if something goes wrong , look at the kubelet log of host where the pod has been deployed, the cifs plugin is a bash script that can be modified in-place on that host ( add affinity to reschedule on same node )

### References

- https://github.com/coreos/coreos-overlay/issues/595
- https://github.com/jamiemccrindle/dockerception
- https://github.com/sigma/cifs_k8s_plugin
- https://docs.docker.com/develop/develop-images/multistage-build/
