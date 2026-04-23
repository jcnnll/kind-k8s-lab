# KIND Kubernetes Lab

## Overview

This project provides a reproducible local Kubernetes lab environment using KIND
to simulate a multi-node cluster.

It includes:

- Multi-node KIND cluster configuration
- Base platform setup (namespaces, RBAC, quotas, limits)
- Ingress controller (nginx)
- Local DNS using dnsmasq
- Trusted TLS using mkcert
- Sample workload (echo service) exposed via HTTPS

The goal is to provide a clean, deterministic starting point for building and
testing workloads against a realistic Kubernetes platform layer.

---

## Architecture

api.lab
  ↓ DNS (dnsmasq → 127.0.0.1)
ingress-nginx
  ↓ TLS termination (mkcert)
Kubernetes Service
  ↓
Pod (echo)

---

## Dependencies

The following must be installed on the host:

- docker
- kind
- kubectl
- mkcert
- dnsmasq

Notes:

- mkcert must be available in PATH
- dnsmasq must be installed via Homebrew (macOS) or system package manager

---

## DNS Configuration (dnsmasq)

This lab uses dnsmasq to resolve the `.lab` domain locally.

### 1. Configure dnsmasq

Create file:

/opt/homebrew/etc/dnsmasq.d/lab.conf

Contents:

address=/.lab/127.0.0.1

---

### 2. Configure system resolver (macOS)

Create file:

/etc/resolver/lab

Contents:

nameserver 127.0.0.1

---

### 3. Restart dnsmasq

brew services restart dnsmasq

---

### 4. Verify DNS

dig api.lab @127.0.0.1

Expected:

api.lab → 127.0.0.1

---

## TLS

TLS certificates are generated using mkcert and injected into Kubernetes
as a TLS secret.

- Certificates are generated at runtime (ephemeral)
- No persistent certificate storage is required
- Ingress uses the secret for HTTPS termination

---

## Usage

### Create cluster and deploy everything

make up

This will:

1. Create KIND cluster
2. Apply platform configuration
3. Install ingress controller
4. Generate TLS certificates
5. Deploy sample workload
6. Validate end-to-end routing

---

### Verify system manually

curl <https://api.lab>

Expected:

hello lab

---

### Platform checks (static)

make check

---

### Runtime validation (end-to-end)

make validate

---

### Destroy cluster

make down

---

## Notes

- No port-forwarding is used
- No manual /etc/hosts changes required
- No browser certificate trust configuration required
- All routing is done via ingress-nginx on localhost (ports 80/443)

---

## Purpose

This lab is intended as a clean foundation for:

- Testing Kubernetes workloads locally
- Practicing platform engineering concepts
- Validating ingress, TLS, and DNS behavior
- Simulating multi-node cluster environments
