# Local Kubernetes Platform

## Overview

This project provides a reproducible, local-first Kubernetes platform
environment designed to simulate key behaviours found in production-grade
cloud deployments.

It is not a tutorial or example application.

It is a **platform foundation** for designing, testing, and validating real
Kubernetes engineering patterns in a safe and deterministic environment.

The primary goal is to enable **environment parity** between local development
and real-world deployment environments without reliance on cloud
infrastructure or paid services.

## Why this exists

Modern platform engineering relies on highly
abstracted infrastructure, but engineers still need a safe way to validate
real Kubernetes behaviours before changes reach shared or production
environments.

This project exists to solve that gap by providing a fully local,
reproducible Kubernetes platform that behaves like a real deployment
environment, including DNS, ingress, TLS, and multi-node cluster
behaviour.

The goal is not to build full application labs, but to establish a
stable, reusable platform foundation that can be extended into focused
scenario-based environments (e.g. GitOps, observability, multi-tenancy)
without re-implementing core infrastructure each time.

This enables rapid, low-cost experimentation while maintaining
environment parity with production-like Kubernetes systems.

## What this enables

This platform allows engineers to safely experiment with and validate:

- Kubernetes platform design patterns
- GitOps workflows
- Multi-tenant namespace strategies
- Ingress and routing configurations
- TLS termination and certificate handling
- DNS resolution behaviour
- Resource governance (quotas, limits, RBAC)

All within a fully local environment.

## Architecture

The platform emulates a simplified cloud-like Kubernetes stack:

```bash

Client (curl / workloads)
        │
        ▼
Local DNS Resolution (*.lab → 127.0.0.1)
        │
        ▼
Kubernetes Platform Layer (KIND multi-node cluster)
        │
        ▼
Ingress Layer (nginx ingress controller + TLS)
        │
        ▼
Service Routing Layer (ClusterIP services)
        │
        ▼
Workloads (replaceable application layer)

```

## Core Design Principles

### 1. Environment Parity

The platform is designed to behave consistently across:

- local environments
- staging environments
- production-like Kubernetes clusters

### 2. Deterministic Infrastructure

Every component is declarative and reproducible:

- no manual setup steps
- no external dependencies beyond the host toolchain
- no cloud requirements

### 3. Platform First, Applications Second

The system is intentionally structured so that:

- the platform layer is stable and reusable
- workloads are interchangeable and disposable

## Repository Structure

```bash

kind/              # Kubernetes cluster definition
                   # (multi-node KIND setup)
platform/          # Core platform layer
                   # (ingress, RBAC, quotas, namespaces)
scripts/           # Automation utilities
                   # (TLS bootstrap, setup helpers)
workloads/         # Example applications
                   # (replaceable scenarios)
Makefile           # Primary orchestration interface

```

## Included Platform Components

### Kubernetes Cluster

Built using KIND to simulate a multi-node Kubernetes environment locally.

### Ingress Layer

An nginx-based ingress controller providing:

- host-based routing
- path-based routing
- TLS termination

**NOTE:** The nginx ingress configuration is vendor in from:

`https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.15.1/deploy/static/provider/cloud/deploy.yaml`

### DNS Layer (Critical Dependency)

Local DNS resolution is a core platform requirement.

It enables `.lab` domains to resolve to the local ingress layer.

Without this, the platform will not function correctly.

```bash

Local DNS Resolution (*.lab → 127.0.0.1)

```

### DNS Host Configuration

This system relies on `dnsmasq` and a system resolver.

#### dnsmasq config (macOS)

```bash

/opt/homebrew/etc/dnsmasq.d/lab.conf

```

```bash

address=/.lab/127.0.0.1

```

#### system resolver (macOS)

```bash

/etc/resolver/lab

```

```bash

nameserver 127.0.0.1

```

#### restart dnsmasq (macOS)

```bash

brew services restart dnsmasq

```

#### verify DNS

```bash
dig api.lab @127.0.0.1

```

Expected:

```bash

api.lab → 127.0.0.1

```

### TLS Layer

Certificates are generated using mkcert and injected as
Kubernetes secrets for HTTPS simulation.

### Platform Controls

- Namespaces
- RBAC policies
- Resource quotas
- Resource limits

## Dependencies

Required tools:

- docker
- kind
- kubectl
- mkcert
- dnsmasq

Notes:

- mkcert must be available in PATH
- dnsmasq must be configured on the host system
- DNS configuration is REQUIRED for full functionality

## Usage

### 1. Start the platform

```bash

make up

```

This will:

- create the KIND cluster
- deploy platform components
- configure ingress and DNS behavior
- generate TLS certificates
- deploy sample workloads

### 2. Validate the platform

```bash

make validate

```

Runs end-to-end checks across:

- DNS resolution
- ingress routing
- TLS termination
- service-to-pod routing

### 3. Test manually

```bash

curl https://api.lab

```

Expected output:

```bash

hello lab

```

### 4. Destroy environment

```bash

make down

```

## Design Intent

This platform exists to solve a specific problem:

> Engineers often cannot safely validate Kubernetes platform behaviour
> without relying on shared, cloud-based, or production-adjacent
> environments.

This leads to:

- slow iteration cycles
- unsafe experimentation
- reliance on expensive infrastructure
- poor environment parity between stages

This project addresses this by providing a fully local, production-like
Kubernetes platform simulation layer.

## Workload Model

The included echo service is intentionally minimal.

It exists only to validate:

- platform routing
- DNS resolution
- ingress behaviour
- TLS termination

It is expected to be replaced by scenario-specific workloads.

## Extension Model

This repository is designed as a **base platform layer**.

It should be:

- cloned, downloaded or forked
- extended into scenario-based labs such as:
  - GitOps workflows
  - observability stacks
  - multi-tenancy experiments
  - CI/CD pipeline simulation

Each extension represents a focused platform engineering scenario built
on top of this foundation.

## Purpose

This project is intended for platform engineers who want to:

- design and test Kubernetes infrastructure patterns locally
- validate deployment strategies before production rollout
- experiment safely with platform-level changes
- maintain environment parity across development workflows

## Summary

A local Kubernetes platform designed to simulate real-world cloud
behaviours and enable safe, reproducible platform engineering
experimentation.
