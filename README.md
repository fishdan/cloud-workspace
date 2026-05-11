# AWS Cloud Workspace

Terraform for private, per-engineer Ubuntu developer workstations on AWS.

The design keeps infrastructure and workstation state separate. Terraform owns the VPC placement, EC2 instance, IAM role, security group, EBS volumes, and outputs. Engineer tools, editor extensions, language runtimes, repositories, and application dependencies are intentionally left to the engineer or a separate bootstrap process.

## Repository Layout

```text
modules/devbox/       Reusable Terraform module for engineer workstations
environments/dev/     Example development environment
README.md             Project overview and operating notes
.gitignore            Terraform and local editor ignores
```

## Design Philosophy

- EC2 instances are disposable.
- Encrypted workspace EBS volumes are persistent and protected from accidental Terraform deletion.
- Instances are private only: no public IPv4 address is assigned.
- SSH is allowed only from VPC/private CIDR ranges you provide.
- Cloud-init performs first-boot basics only: user creation, SSH key setup, basic packages, and workspace mounting.
- Terraform does not manage personal development state after first boot.

## Prerequisites

- Terraform 1.5 or newer.
- AWS credentials configured for the target account.
- An existing VPC with at least one private subnet.
- Network path to the VPC for SSH, such as VPN, Direct Connect, bastion, or SSM-based tunneling you manage separately.
- Engineer SSH public keys.

## Quick Start

```bash
cd environments/dev
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your VPC ID, private subnet IDs, allowed SSH CIDR blocks, and engineers.

```bash
terraform init
terraform plan
terraform apply
```

## Add A New Engineer

Add an entry to the `engineers` map:

```hcl
engineers = {
  alice = {
    username            = "alice"
    ssh_public_key      = "ssh-ed25519 AAAA..."
    instance_type       = "t3.large"
    workspace_size_gb   = 100
    enabled             = true
  }
}
```

`enabled = false` removes the engineer from the active module graph. Because workspace volumes use `prevent_destroy`, Terraform will stop before deleting protected data. See the destruction notes below.

## Connect With VS Code Remote SSH

After apply, print the generated SSH config:

```bash
terraform output ssh_config
```

Add the relevant host block to your SSH config, then use the VS Code Remote SSH extension to connect to that host.

The instance is private, so SSH only works from a network path that can reach the private IP.

## Forward Ports For Browser Testing

Forward a local port to a service running on the workstation:

```bash
ssh -L 3000:localhost:3000 devbox-alice
```

Then open `http://localhost:3000` on your local machine.

## Workspace Data

The persistent workspace volume is mounted at `/workspace`. The cloud-init script creates an ext4 filesystem only when the volume has no filesystem. Existing restored volumes are mounted without formatting.

## Snapshot A Workspace Volume

Find the volume ID:

```bash
terraform output workspace_volume_ids
```

Create a snapshot:

```bash
aws ec2 create-snapshot \
  --volume-id vol-0123456789abcdef0 \
  --description "alice workspace backup"
```

Tag snapshots with engineer, environment, and purpose so they can be found later.

## Restore A Workspace Volume

Create a new EBS volume from the snapshot in the same Availability Zone as the target private subnet, then import or wire that volume into Terraform before attaching it to a replacement instance. Do not attach the old and restored volume at the same mount point at the same time.

For v1, the safest restore flow is:

1. Snapshot the existing volume.
2. Create a restored volume from the snapshot.
3. Update Terraform state/config intentionally, or create a new engineer entry pointed at a subnet in the restored volume's Availability Zone.
4. Apply and verify `/workspace` contents.

## Intentionally Destroy A Workstation

Workspace volumes are protected with `prevent_destroy = true`.

To destroy only the disposable EC2 instance, remove or disable the engineer and keep the workspace volume in Terraform state. Terraform will still refuse to delete the protected EBS volume.

To permanently delete a workspace volume:

1. Create and verify a final snapshot.
2. Remove `prevent_destroy` from the workspace volume resource in `modules/devbox/main.tf`.
3. Run `terraform plan` and confirm the exact volume ID marked for deletion.
4. Run `terraform apply`.
5. Restore `prevent_destroy` afterward.

This friction is intentional.

## Cost Considerations

Main cost drivers are EC2 instance hours, gp3 root volumes, gp3 workspace volumes, snapshots, and data transfer. Instances in this v1 do not auto-stop. Stop unused instances manually or add a separate scheduling mechanism later.

## Security Assumptions

- Instances are launched without public IPv4 addresses.
- Security groups allow SSH only from configured private CIDR ranges.
- Root and workspace volumes are encrypted.
- IMDSv2 is required.
- IAM permissions are minimal by default; the instance role has no broad managed policy attached.
- OS patching, endpoint detection, SSM access, and centralized identity are outside v1.

## What Terraform Does Not Manage

- Personal dotfiles.
- VS Code extensions.
- Language runtimes.
- Application repositories and dependencies.
- Long-running services inside the workstation.
- GUI access.
- NAT gateways, golden AMIs, SSO, DCV, and auto-shutdown.

These can be added later without changing the core principle: infrastructure is reproducible, data is persistent, and instances are replaceable.
