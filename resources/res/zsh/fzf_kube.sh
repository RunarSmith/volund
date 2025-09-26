
_fzf_k8s_get_pods() {
  kubectl get pod --no-headers -o custom-columns=':metadata.name' | fzf
}
_fzf_k8s_get_services() {
  kubectl get svc --no-headers -o custom-columns=':metadata.name' | fzf
}
_fzf_k8s_get_namespaces() {
  kubectl get ns --no-headers -o custom-columns=':metadata.name' | fzf
}
_fzf_k8s_get_deploy() {
  kubectl get ns --no-headers -o custom-columns=':metadata.name' | fzf
}
