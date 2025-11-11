# kerno-agent-runtimes

## Introduction

This repository houses the kerno agent's runtime files along with install scripts for ease of use

> [!NOTE]
> Right now the Kerno agent is intended to be installed and run with our VSCode extension, no support
or documentation is offered (yet) for running and configuring the agent outside the extension

## Installing

Versions are baked into the scripts on each release, to install the latest kerno agent available run:

### Linux/Mac (x64 and aarch64)

```shell
curl -fsSL https://raw.githubusercontent.com/kernoio/kerno-agent-runtimes/main/install.sh | bash
```

### Windows (x64)

```powershell
irm https://raw.githubusercontent.com/kernoio/kerno-agent-runtimes/main/install.ps1 | iex
```