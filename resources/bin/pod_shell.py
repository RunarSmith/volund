# !/usr/bin/env python3

# python3-kubernetes

import sys
import os
import signal
import select
import termios
import tty

from kubernetes import config
from kubernetes.client import CoreV1Api
from kubernetes.stream import stream

NAMESPACE = None
CONTAINER = None

BUFFER = r"""
# Colors
RED="\[\e[1;31m\]"
GREEN="\[\e[1;32m\]"
CYAN="\[\e[1;36m\]"
BLUE="\[\e[1;34m\]"
YELLOW="\[\e[1;33m\]"
RESET="\[\e[0m\]"

# Return 3 last folder levels of current directory, with ~ or "…"
_pwd_last3() {
  # replace $HOME with ~
  local path="${PWD/#$HOME/~}"
  IFS='/' read -r -a parts <<< "$path"
  # return simple cases: ~, /, short paths
  if [[ ${#parts[@]} -le 4 ]]; then
    printf '%s' "$path"
    return
  fi
  # Build longuer path: .../a/b/c
  local last3=("${parts[@]: -3}")
  printf '…/%s' "$(IFS='/'; echo "${last3[*]}")"
}

# Prompt on 2 lines
export PS1="\n${GREEN}\u${RESET}@${CYAN}\h ${BLUE}\$(_pwd_last3)${RESET}\n${YELLOW}└─>${RESET} "
alias l='ls -aFhl'
alias ll='ls -aFl'
alias lrt='ls -aFhlrt'
"""

class RawTerminal:
    def __init__(self):
        self.fd = sys.stdin.fileno()
        self.old_attrs = termios.tcgetattr(self.fd)

    def __enter__(self):
        tty.setraw(self.fd)
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        termios.tcsetattr(self.fd, termios.TCSADRAIN, self.old_attrs)

def handle_sigint(signum, frame):
    # Do not kill our-self on CTRL+C. just send it raw to remote shell via stdin
    pass

signal.signal(signal.SIGINT, handle_sigint)

def get_current_namespace():
    """
    Get current namespace from context
    fallback : 'default'
    """
    try:
        contexts, active_context = config.list_kube_config_contexts()
        if active_context and "context" in active_context:
            ctx = active_context["context"]
            if "namespace" in ctx:
                return ctx["namespace"]
    except Exception:
        pass
    # Fallback
    return "default"

def open_shell_with_buffer(pod_name, namespace=NAMESPACE, container=CONTAINER):
    config.load_kube_config()
    v1 = CoreV1Api()

    # login shell
    exec_command = ["/bin/sh", "-l"]

    ws_client = stream(
        v1.connect_get_namespaced_pod_exec,
        pod_name,
        namespace,
        container=container,
        command=exec_command,
        stderr=True,
        stdin=True,
        stdout=True,
        tty=True,
        _preload_content=False,
    )

    # Switch TTY to raw on client side
    with RawTerminal():
        try:
            # 1) Inject buffer just as if user send it
            for line in BUFFER.splitlines():
                if not line.strip():
                    continue
                ws_client.write_stdin(line + "\n")
            # Optional : force flush / prompt
            ws_client.write_stdin("\n")

            # 2) Loop for interractive
            while ws_client.is_open():
                if ws_client.peek_stdout():
                    out = ws_client.read_stdout()
                    if out:
                        os.write(sys.stdout.fileno(), out.encode())

                if ws_client.peek_stderr():
                    err = ws_client.read_stderr()
                    if err:
                        os.write(sys.stderr.fileno(), err.encode())

                rlist, _, _ = select.select([sys.stdin], [], [], 0.01)
                if sys.stdin in rlist:
                    data = os.read(sys.stdin.fileno(), 1024)
                    if not data:
                        ws_client.write_stdin("\nexit\n")
                        break
                    ws_client.write_stdin(data.decode(errors="ignore"))

        finally:
            ws_client.close()

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print(f"Usage : {sys.argv[0]} <pod-name> [namespace]", file=sys.stderr)
        sys.exit(1)

    pod = sys.argv[1]

    if len(sys.argv) > 2:
        ns = sys.argv[2]
    else:
        # Load kubeconfig before list_kube_config_contexts
        try:
            config.load_kube_config()
        except Exception:
            pass
        ns = get_current_namespace()
    open_shell_with_buffer(pod, namespace=ns, container=CONTAINER)
