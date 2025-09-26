
# OpenShift CLI (oc)

% openshift, oc, cli

## login to cluster
#platform/linux  #target/cluster  #cat/AUTH
```
oc login https://<cluster-url> --token=<token>
```

## show current user
#platform/linux  #target/local  #cat/INFO
```
oc whoami
```

## get current project
#platform/linux  #target/cluster  #cat/CONTEXT
```
oc project -q
```

## switch project/namespace
#platform/linux  #target/cluster  #cat/CONTEXT
```
oc project <namespace>
```

## list all resources in current namespace
#platform/linux  #target/cluster  #cat/ENUM
```
oc get all
```

## describe a pod
#platform/linux  #target/cluster  #cat/INSPECT
```
oc describe pod <pod-name>
```

## view logs of a pod
#platform/linux  #target/cluster  #cat/LOGS
```
oc logs <pod-name>
```

## follow logs of a pod
#platform/linux  #target/cluster  #cat/LOGS
```
oc logs -f <pod-name>
```

## exec into a pod
#platform/linux  #target/cluster  #cat/INTERACT
```
oc exec -it <pod-name> -- /bin/bash
```

## apply a resource file
#platform/linux  #target/cluster  #cat/DEPLOY
```
oc apply -f <file>.yaml
```

## delete a resource
#platform/linux  #target/cluster  #cat/DELETE
```
oc delete <resource> <name>
```

## edit a resource live
#platform/linux  #target/cluster  #cat/MODIFY
```
oc edit <resource> <name>
```

## scale a deployment
#platform/linux  #target/cluster  #cat/DEPLOY
```
oc scale deploy/<name> --replicas=<replicas_nb>
```

## restart a deployment
#platform/linux  #target/cluster  #cat/DEPLOY
```
oc rollout restart deploy/<name>
```

## check rollout status
#platform/linux  #target/cluster  #cat/DEPLOY
```
oc rollout status deploy/<name>
```

## list events (raw)
#platform/linux  #target/cluster  #cat/MONITOR
```
oc get events
```

## list events, sorted by time
#platform/linux  #target/cluster  #cat/MONITOR
```
kubectl get events --sort-by='.lastTimestamp'
```

## list events, and keep watching
#platform/linux  #target/cluster  #cat/MONITOR
```
kubectl get events -w
```

## top pods (CPU/mem)
#platform/linux  #target/cluster  #cat/MONITOR
```
oc top pod
```

## list pods, sorted by restart count (all namespaces)
#platform/linux  #target/cluster  #cat/MONITOR
```
kubectl get pods --all-namespaces --sort-by='.status.containerStatuses[0].restartCount'
```

## list pods, sorted by restart count (current namespace)
#platform/linux  #target/cluster  #cat/MONITOR
```
kubectl get pods --sort-by='.status.containerStatuses[0].restartCount'
```

## port forward to pod
#platform/linux  #target/cluster  #cat/NETWORK
```
oc port-forward <pod-name> <local-port>:<remote-port
```

## list service accounts
#platform/linux  #target/cluster  #cat/SECURITY
```
oc get sa
```

## list roles and bindings
#platform/linux  #target/cluster  #cat/SECURITY
```
oc get roles
oc get rolebindings
```

## add role to user
#platform/linux  #target/cluster  #cat/SECURITY
```
oc adm policy add-role-to-user <role> <user>
```

## check permissions
#platform/linux  #target/cluster  #cat/SECURITY
```
oc auth can-i <verb> <resource>
```

## list PVCs
#platform/linux  #target/cluster  #cat/STORAGE
```
oc get pvc
```

## describe PVC
#platform/linux  #target/cluster  #cat/STORAGE
```
oc describe pvc <name>
```

## list CRDs
#platform/linux  #target/cluster  #cat/CRD
```
oc get crd
```

## list objects of a CRD
#platform/linux  #target/cluster  #cat/CRD
```
oc get <crd-name>
```

## explain a resource
#platform/linux  #target/local  #cat/DOCS
```
oc explain <resource>
```

## list all API resources
#platform/linux  #target/local  #cat/DOCS
```
oc api-resources
```

## generate zsh completion
#platform/linux  #target/local  #cat/UTIL
```
oc completion zsh
```

## get cluster operator with statuses
#platform/linux  #target/local  #cat/UTIL
```
oc get clusteropedrator
```

## get cluster operator with error
#platform/linux  #target/local  #cat/UTIL
```
oc get clusteropedrator | grep -v 'True        False         False'
```

## extract scret content
#platform/linux  #target/local  #cat/UTIL
```
oc extract secret/<secret-name> --to=-
```

## get egress (IP + DNS)
#platform/linux  #target/local  #cat/UTIL
```
egressName=<egress-name|default>
echo "CIDR\t\t\t\tTYPE\tPORT"
oc get egressfirewall $egressName -o json | jq -r '.spec.egress[] | select(.to.dnsName      != null) | [.to.dnsName,.type,.ports[]?.port ] | @tsv' | grep -Ev '^$'
oc get egressfirewall $egressName -o json | jq -r '.spec.egress[] | select(.to.cidrSelector != null) | [.to.cidrSelector,.type,.ports[]?.port ] | @tsv' | grep -Ev '^$'
```
