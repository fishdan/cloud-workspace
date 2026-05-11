# AWS Cloud Desktop

Terraform for per-engineer Ubuntu developer workstations on AWS.

The design keeps infrastructure and workstation state separate. Terraform owns the VPC placement, EC2 instance, IAM role, security group, EBS volumes, and outputs. Engineer tools, editor extensions, language runtimes, repositories, and application dependencies are intentionally left to the engineer or a separate bootstrap process.

## Repository Layout

```text
modules/devbox/       Reusable Terraform module for engineer cloud desktops
environments/dev/     Example development environment
README.md             Project overview and operating notes
AGENTS.md             AI agent guidance for safe repo work
.gitignore            Terraform and local editor ignores
```

## Design Philosophy

- EC2 instances are disposable.
- Encrypted workspace EBS volumes are persistent and protected from accidental Terraform deletion.
- The current implementation uses public IPv4 plus tightly scoped SSH ingress because it is the simplest path for a small setup.
- Private networking with Tailscale, VPN, bastion, or NAT-backed private subnets remains supported as an evolution path.
- Cloud-init performs first-boot basics only: user creation, SSH key setup, basic packages, and workspace mounting.
- Terraform does not manage personal development state after first boot.

## Access Decision

The default workflow is direct SSH over the instance public IPv4 address, including VS Code Remote SSH and normal SSH local port forwarding. Engineers already understand this workflow, it works naturally with editor tooling, and it lets a service running on the workstation be tested from the engineer's local browser as if it were running on localhost.

This is intentionally pragmatic. The existing AWS account already has a default VPC with public subnets and internet gateway routing. Reusing one of those subnets avoids adding NAT Gateway cost and avoids requiring Tailscale, VPN, Direct Connect, or a bastion before the first workstation is usable.

The tradeoff is exposure: SSH is reachable from the internet wherever the security group allows it. Keep `allowed_ssh_cidr_blocks` to a narrow `/32` for your current public IP whenever possible. Do not use `0.0.0.0/0`.

Alternative access paths:

- **Public SSH, selected for this implementation:** easiest to operate, no NAT Gateway, no overlay network, works directly with VS Code Remote SSH. The downside is that the instance has a public IP and SSH must be carefully restricted.
- **Elastic IP with public SSH:** keeps the SSH endpoint stable across stop/start cycles. The downside is a continuing public IPv4 charge while allocated, including while the instance is stopped.
- **Tailscale on the instance:** keeps access ergonomic and avoids opening SSH to the internet, but the instance still needs outbound internet to install and join Tailscale. In a private subnet that usually means NAT, or a prebuilt AMI.
- **Private subnet plus NAT:** best fit for a reusable platform because the instance has no public IP while still having outbound internet for package installs and Tailscale. The downside is NAT Gateway cost and more network infrastructure.
- **VPN, Direct Connect, or bastion:** mature private access patterns, but they add operational setup before an engineer can connect.

## Prerequisites

- Terraform 1.5 or newer.
- AWS credentials configured for the target account.
- An existing VPC with at least one subnet. The example uses an existing public subnet.
- SSH CIDR blocks scoped to trusted source IPs, ideally your current public IP as `/32`.
- Engineer SSH public keys.

## Quick Start

```bash
cd environments/dev
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your VPC ID, subnet IDs, allowed SSH CIDR blocks, and engineers.

For the public SSH route, set `allowed_ssh_cidr_blocks` to your current public IP as `/32`. For example:

```bash
curl https://checkip.amazonaws.com
```

```bash
terraform init
terraform plan
terraform apply
```

For local account-specific values that should never be committed, use an ignored live vars file instead:

```bash
terraform plan -var-file=cloud-desktop.live.tfvars
terraform apply -var-file=cloud-desktop.live.tfvars
```

## Add A New Engineer

Add an entry to the `engineers` map:

```hcl
engineers = {
  alice = {
    username            = "alice"
    ssh_public_key      = "ssh-ed25519 AAAA..."
    instance_type       = "t3.small"
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

When `assign_public_ip = true`, the generated SSH config points at the instance public IP. When `assign_public_ip = false`, it points at the private IP and you need a private network path such as Tailscale, VPN, Direct Connect, bastion, or SSM-based tunneling.

When `use_elastic_ip = true`, Terraform allocates an Elastic IP and the generated SSH config points at that stable address. This is useful with auto-stop because a stopped and restarted EC2 instance otherwise usually receives a new auto-assigned public IPv4 address.

## Auto-Stop

Auto-stop is optional and uses a CloudWatch alarm per workstation. When `enable_auto_stop = true`, Terraform creates an alarm that stops the EC2 instance after sustained low average CPU:

```hcl
enable_auto_stop                = true
auto_stop_idle_minutes          = 60
auto_stop_period_seconds        = 300
auto_stop_cpu_threshold_percent = 5
```

This is CPU-based inactivity, not keyboard or editor activity. It works well as a cost guardrail, but a quiet SSH or VS Code session can still be considered idle if CPU remains below the threshold for the whole window. Increase the idle minutes or threshold behavior if that is too aggressive.

Stopping the instance preserves the encrypted workspace EBS volume. If `use_elastic_ip = true`, the SSH endpoint remains stable after you start the instance again.

To start a stopped workstation, use the AWS console or CLI:

```bash
aws ec2 start-instances --instance-ids i-0123456789abcdef0
```

## Optional Tailscale Access

Tailscale can provide that private network path without assigning public IP addresses to the workstations. To enable it, generate a Tailscale auth key from the admin console and set `tailscale_auth_key` in `terraform.tfvars`:

```hcl
tailscale_auth_key      = "tskey-auth-REPLACE_ME"
tailscale_enable_ssh    = false
tailscale_accept_routes = false
```

When enabled, cloud-init installs Tailscale, runs `tailscale up`, and sets each node hostname to `${project_name}-${environment}-${engineer_key}`, such as `cloud-desktop-dev-alice`.

After apply, print the generated Tailscale SSH config:

```bash
terraform output tailscale_ssh_config
```

Add the relevant host block to your SSH config, then connect with VS Code Remote SSH using the `cloud-desktop-alice-ts` host alias. This still uses normal OpenSSH on the workstation; `tailscale_enable_ssh` controls Tailscale SSH separately and defaults to `false`.

Treat the Tailscale auth key as sensitive. Terraform passes it through EC2 user data, so it can be present in Terraform state and cloud-init logs. Prefer a tagged, reusable, pre-approved auth key scoped for these workstations, and store Terraform state in an encrypted backend with restricted access.

## Forward Ports For Browser Testing

Use SSH local port forwarding to test a service running on the workstation from your local browser. For a dev server listening on the workstation at `localhost:3000`, forward it to your laptop:

```bash
ssh -L 3000:localhost:3000 cloud-desktop-alice
```

Then open `http://localhost:3000` on your local machine.

This keeps the browser, cookies, local debugging tools, and OAuth redirect behavior on the engineer's laptop while the application server and code run on the cloud workstation.

If direct SSH is not reachable, an SSM tunnel can provide equivalent local port forwarding, but it is treated as a fallback access mechanism rather than the default developer experience.

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

Create a new EBS volume from the snapshot in the same Availability Zone as the target subnet, then import or wire that volume into Terraform before attaching it to a replacement instance. Do not attach the old and restored volume at the same mount point at the same time.

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

Main cost drivers are EC2 instance hours, gp3 root volumes, gp3 workspace volumes, snapshots, and data transfer. Enable auto-stop for a cost guardrail, and stop unused instances manually when needed.

Public IPv4 addresses are also billed hourly. AWS charges the same public IPv4 hourly rate for auto-assigned public IPv4 addresses while in use and Elastic IPs while allocated. An Elastic IP keeps costing money even while the EC2 instance is stopped.

## Security Assumptions

- In this implementation, instances may be launched with public IPv4 addresses.
- Security groups allow SSH only from configured CIDR ranges. For public SSH, use a narrow `/32` source IP whenever possible.
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
- NAT gateways, golden AMIs, SSO, and DCV.

These can be added later without changing the core principle: infrastructure is reproducible, data is persistent, and instances are replaceable.
