# Cloud-Native Network Security & Observability with eBPF

Cilium eBPF-based CNI deployed on a Kind cluster, replacing iptables/kube-proxy with kernel-level traffic processing and granular security enforcement across a multi-tenant namespace setup.

## Architecture

```
Kind Cluster
├── tenant-1 (namespace)
├── tenant-2 (namespace)
└── tenant-3 (namespace)
         ↓
  Cilium eBPF CNI
  (replaces kube-proxy + iptables)
         ↓
Hubble · Prometheus · Grafana
```

## Network Policies

| Layer | Enforcement |
|-------|-------------|
| L3/L4 | Inter-tenant traffic blocked by default |
| L4 | Port restrictions per namespace |
| L7 | HTTP method filtering per service |

## Setup

```bash
git clone https://github.com/mimii020/Network-Security-And-Observability-With-eBPF.git
cd Network-Security-And-Observability-With-eBPF

bash scripts/setup-cluster.sh
bash scripts/deploy-hubble.sh
bash scripts/apply-policies.sh

cilium connectivity test
```

## Prerequisites

- Docker, kind, kubectl, helm, cilium CLI

## Stack

Kubernetes (Kind) · Cilium · Hubble · Prometheus · Grafana

---
**Imen Abidi** · [GitHub](https://github.com/mimii020) · [LinkedIn](https://linkedin.com/in/imen-abidi)
