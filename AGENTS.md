# AGENTS.md

Guidance for AI coding agents working in this repository.

## Project Purpose

This repo provisions per-engineer Ubuntu cloud desktops on AWS with Terraform.

The current deployment path is intentionally simple:

- Reuse an existing VPC and public subnet.
- Assign a public IPv4 address to the EC2 instance.
- Restrict inbound SSH to a narrow CIDR, ideally the user's current public IP as `/32`.
- Mount a separate encrypted gp3 EBS workspace volume at `/workspace`.

Optional Tailscale support exists in the module, but public SSH is the primary path documented for the first implementation.

## Repo Layout

```text
modules/devbox/       Reusable Terraform module
environments/dev/     Example deployable environment
README.md             Human setup and operations guide
.gitignore            Terraform state, vars, and local artifact ignores
```

## Safety Rules

- Do not commit real AWS account values, public IPs, SSH public keys for real users, auth keys, secrets, or Terraform state.
- Keep real deployment values in ignored files such as `environments/dev/cloud-desktop.live.tfvars`.
- Keep `terraform.tfvars.example` generic with placeholder IDs and example CIDRs only.
- Never remove `prevent_destroy` from the workspace EBS volume unless the user explicitly asks to permanently delete workspace data.
- Do not run `terraform apply` unless the user explicitly approves it.
- Prefer scoped edits. This repo is meant to stay readable for a small team.

## Common Commands

From the repo root:

```bash
terraform fmt -recursive
terraform -chdir=environments/dev validate
terraform -chdir=environments/dev plan -var-file=cloud-desktop.live.tfvars
```

Use `plan` for verification. Use `apply` only after explicit user approval:

```bash
terraform -chdir=environments/dev apply -var-file=cloud-desktop.live.tfvars
```

After apply:

```bash
terraform -chdir=environments/dev output ssh_config
terraform -chdir=environments/dev output public_ips
terraform -chdir=environments/dev output workspace_volume_ids
```

## Security Audit Checklist

Before committing or pushing, run checks similar to:

```bash
git status --short --ignored
git grep -n -E '(AKIA|ASIA|aws_secret_access_key|BEGIN .*PRIVATE KEY|tskey-|ghp_|github_pat_|password\\s*=|secret\\s*=|token\\s*=)'
git grep -n -E '(vpc-[0-9a-f]{8,}|subnet-[0-9a-f]{8,}|[0-9]{1,3}(\\.[0-9]{1,3}){3}/32)'
git diff --check
```

Expected safe hits include placeholders such as:

- `vpc-0123456789abcdef0`
- `subnet-0123456789abcdef0`
- `203.0.113.10/32`
- `tskey-auth-REPLACE_ME`

Ignored live files and state should appear as ignored, not untracked or staged.

## Design Notes

- EC2 instances are disposable.
- Workspace EBS volumes are persistent and protected with `prevent_destroy`.
- Cloud-init should stay minimal: user creation, SSH key setup, basic packages, optional Tailscale, and workspace mounting.
- Terraform manages infrastructure only, not personal dotfiles, editor extensions, language runtimes, application repositories, or services.
