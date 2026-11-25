# Jenkins Infrastructure POC — Agent Instructions

## Objective

Build a reproducible Jenkins controller and Linux/Windows agents using Vagrant, Ansible and Jenkins Configuration as Code (JCasC). Replace manual installation and plugin copying. The first iteration is internet-connected; air-gap support comes later.

## Collaboration rules

- Work interactively with the user, one milestone at a time. Present choices and trade-offs before implementing the next milestone.
- Start with milestone 1 only. Do not implement the entire roadmap at once.
- Inspect the host, installed Vagrant version, available providers and boxes before choosing dependencies. Verify upstream documentation and compatibility; do not invent box names or versions.
- Explain proposed changes, commands, validation results and blockers. Stop for user approval at milestone boundaries.
- Keep configuration version-controlled, modular and idempotent. Pin tested versions and avoid committing credentials, tokens, private keys or generated VM state.
- Ask before destructive actions, including destroying VMs. Do not disable SELinux, firewalls or certificate verification as a shortcut.

## Proposed BOM

These are starting defaults, not mandatory decisions. Confirm the hypervisor, Windows box availability/licensing and network subnet with the user.

| Host                  | OS                             | vCPU |  RAM | Private IP   |
| --------------------- | ------------------------------ | ---: | ---: | ------------ |
| jenkins-controller    | Rocky Linux 9                  |    4 | 8 GB | 192.168.1.70 |
| jenkins-agent-linux   | Rocky Linux 9                  |    2 | 4 GB | 192.168.1.71 |
| jenkins-agent-windows | Windows Server 2022 (proposed) |    4 | 8 GB | 192.168.1.72 |

VirtualBox is a proposed Vagrant provider, not a confirmed requirement. Windows box selection may require a separate evaluation-image or custom-box workflow. Keep Windows work staged if it blocks Linux progress.

## Architecture and responsibilities

- Vagrant: VM lifecycle, networking, hostnames and minimal bootstrap.
- Jenkins controller: also acts as the Ansible control node; no fourth VM. Ansible uses local connection for controller, SSH for Linux agent, and WinRM or PSRP for Windows agent.
- Ansible: OS configuration, Java, Jenkins packages, plugins, services and agent prerequisites.
- JCasC: Jenkins application configuration, security, credential references and agent definitions.
- Jenkins Plugin Installation Manager: resolve and install a pinned plugin set compatible with the selected Jenkins LTS version.
- Git: source of truth for desired configuration. Jenkins runtime state and secrets are separate.
- Future: Artifactory for approved packages and dependencies; S3 for protected backups; Vault for secrets if appropriate.

## Roadmap and acceptance gates

### 1. Vagrant infrastructure (start here)

Create a multi-machine Vagrantfile with the three named machines, configurable resources, private networking and internet access. Confirm provider and compatible boxes first. Bootstrap Ansible on the controller with minimal provisioning (or explicitly defer installation to milestone 2). Do not install Jenkins yet. Validate VM status, OS versions, hostnames, IPs and connectivity. Bring up Linux machines first if Windows needs additional work.

### 2. Ansible bootstrap

Create inventory and ansible.cfg; install Ansible and required collections/dependencies on the controller. Establish secure SSH and Windows WinRM/PSRP access. Verify local connectivity, ansible.builtin.ping for Linux and ansible.windows.win_ping for Windows. Avoid embedding passwords in Git.

### 3. Jenkins controller

Create an Ansible role for a supported Java version, pinned Jenkins LTS, systemd, filesystem permissions and required firewall rules. Verify service health and HTTP access. Do not schedule builds on the controller.

### 4. Plugin management

Create plugins.txt and use Jenkins Plugin Installation Manager. Resolve transitive dependencies against the selected Jenkins version, record the resolved versions and verify startup. Avoid manually copying plugins.

### 5. Configuration as Code

Create JCasC YAML for Jenkins settings, security, credentials references and agent definitions. Choose a secure bootstrap mechanism. Verify configuration loads after restart without manual UI setup. Consider Job DSL for test jobs.

### 6. Linux agent

Install compatible Java, Git and minimal build tools through Ansible. Choose SSH or inbound agent transport with the user. Configure labels, workspace and persistent connectivity as applicable. Verify the agent is online and runs a test pipeline.

### 7. Windows agent

Install compatible Java, Git and PowerShell tooling via Ansible. Choose agent transport and persistent service mechanism with the user. Validate service identity, permissions, connectivity and a Windows test pipeline.

### 8. End-to-end validation

Run pipelines on both agents. Re-run Ansible and check idempotency. With explicit user approval, destroy and rebuild the lab, then verify that one documented playbook invocation restores the desired Jenkins configuration. Distinguish fresh provisioning from restoring runtime data.

### 9. Air-gapped adaptation (deferred)

Inventory all external dependencies: OS repositories, Java, Jenkins RPM/WAR, plugins and metadata, Ansible collections, Python packages, Windows installers and build tools. Resolve and scan artifacts in a connected staging environment, record checksums and versions, and publish approved artifacts to internal Artifactory. Replace external URLs with internal sources. Plan encrypted, access-controlled S3 backups and test restore, including Jenkins credential encryption material where required. Validate provisioning with external network access blocked. Do not implement this phase during the initial POC.

## Suggested repository layout

Evolve the layout as needed; do not create empty scaffolding unnecessarily.

```text
jenkins-infrastructure/
├── AGENTS.md
├── README.md
├── Vagrantfile
├── ansible/
│   ├── ansible.cfg
│   ├── inventory.yaml
│   ├── requirements.yaml
│   ├── site.yaml
│   └── roles/
│       ├── jenkins-controller/
│       ├── jenkins-agent-linux/
│       └── jenkins-agent-windows/
├── jcasc/
│   └── jenkins.yaml
└── plugins/
    └── plugins.txt
```

## Target workflow (not implemented yet)

```bash
vagrant up
vagrant ssh jenkins-controller
# From the agreed repository path on the controller:
cd ansible
ansible-playbook -i inventory.yaml site.yaml
```

Agree on how repository files reach the controller (Vagrant shared folder or Git checkout). Document exact commands after testing.

## Upstream references

- https://developer.hashicorp.com/vagrant/docs
- https://docs.ansible.com/
- https://www.jenkins.io/doc/book/installing/linux/
- https://github.com/jenkinsci/plugin-installation-manager-tool
- https://github.com/jenkinsci/configuration-as-code-plugin
- https://github.com/geerlingguy/ansible-role-jenkins (evaluate before adoption)

## First action

Inspect the local host and Vagrant/provider availability. Present the Rocky Linux and Windows box options, including licensing and compatibility considerations. Agree on the provider and VM defaults, then implement and validate milestone 1 only.
