# vtmm-eks — Terraform EKS with multi-environment CI/CD

Reusable, environment-driven EKS infrastructure (dev, uat, prod) built with Terraform
modules and deployed through GitHub Actions with per-environment **manual approval** gates.

## Repository layout

```
.
├── main.tf                  # Root: composes the vpc + eks modules
├── variables.tf             # Environment-injected variables
├── outputs.tf
├── versions.tf              # AWS provider + default tags
├── Makefile                 # Local workflow (plan/apply/destroy/bootstrap)
├── modules/
│   ├── vpc/                 # Reusable VPC (public/private subnets, NAT, routes)
│   └── eks/                 # Reusable EKS (cluster, node groups, IAM, KMS, SG)
├── envs/
│   ├── dev/                 # dev.tfvars + backend.hcl
│   ├── uat/                 # uat.tfvars + backend.hcl
│   └── prod/                # prod.tfvars + backend.hcl
├── bootstrap/               # One-time: state buckets, lock table, GitHub OIDC role
└── .github/workflows/
    ├── terraform-plan-reusable.yml    # Reusable plan (+ PR comment)
    ├── terraform-apply-reusable.yml   # Reusable apply/destroy (environment-gated)
    ├── apply-dev.yml
    ├── apply-uat.yml
    └── apply-prod.yml
```

## Design decisions (best practices)

- **Remote state with locking** — one S3 bucket per environment (blast-radius isolation),
  versioned and SSE-encrypted. State **locking is handled by a shared DynamoDB table**
  (`dynamodb_table`), with `use_lockfile = false` so S3-native conditional-write locking is
  disabled — DynamoDB remains the single source of truth for concurrency control.
- **Reusable modules** — `vpc` and `eks` are parameterized modules; only
  `envs/<env>/*` change between environments (no duplicated module code).
- **Environment isolation** — separate VPC CIDR, subnet ranges, node-group sizing and
  capacity strategy per environment (dev=SPOT, prod=ON_DEMAND + SPOT).
- **Least-privilege GitHub access** — GitHub Actions authenticates via **OIDC
  federation** (no long-lived AWS keys) to a single IAM role that can read/write state
  and provision EKS resources.
- **Manual approval** — apply/destroy jobs target the GitHub `environment` (`dev`,
  `uat`, `prod`). Configure **required reviewers** on uat/prod environments so a human
  must approve before changes deploy.
- **Bolts**: KMS encryption for cluster secrets, control-plane logging, private-only
  cluster endpoint, cluster-autoscaler-friendly node groups with launch templates.

## Prerequisites

1. Terraform >= 1.11 (required for `use_lockfile` support) and AWS credentials with
   permission to create S3/DynamoDB/IAM/EC2/EKS.
2. A GitHub repository at `vitaltechmyanmar/vtmm-eks-terraform`.
3. GitHub **Environments** named `dev`, `uat`, `prod` (Settings → Environments).
4. Two repo-level **secrets** and one **variable**:
   - Secret `AWS_OIDC_ROLE_ARN` → set to the output of bootstrap (see below).
   - Variable `AWS_REGION` (optional, currently hardcoded to `ap-southeast-1`).

## State storage & locking

Backends are defined per environment in `envs/<env>/backend.hcl` and injected at init:

```
bucket         = "vtmm-eks-tfstate-<env>-ap-southeast-1"   # S3 stores the state file
key            = "<env>/terraform.tfstate"
use_lockfile    = true                                     # S3-native locking
encrypt         = true
```

- **State file** lives in a per-environment S3 bucket (versioned + SSE-encrypted).
- **Locking** S3-native locking.
- The GitHub Actions OIDC role is granted exactly the DynamoDB permissions Terraform
  needs for locking (`GetItem`, `PutItem`, `DeleteItem`) plus the state S3 access.


## 1 — Bootstrap (one-time)

Run once with an admin session to create the state buckets, lock table and the
GitHub OIDC role:

```bash
make bootstrap
```

Grab the role ARN:

```bash
cd bootstrap
terraform output github_oidc_role_arn    # e.g. arn:aws:iam::123456789012:role/vtmm-eks-gha
```

Then configure **required reviewers** on the `uat` and `prod` GitHub environments to
enforce manual approval.

## 2 — Local plan/apply

```bash
# dev (default), uat or prod
make plan            # ENV=dev
make plan ENV=uat
make plan ENV=prod

make apply           # ENV=dev (uses tfplan from 'make plan')
make destroy ENV=prod
```

## 3 — CI/CD via GitHub Actions

| Trigger | dev | uat | prod |
|---|---|---|---|
| PR to branch | plan only (+ PR comment) | plan only | plan only (PR to `main`) |
| `workflow_dispatch` `action=plan` | plan | plan | plan |
| `workflow_dispatch` `action=apply` | apply | apply (requires env approval) | apply (requires env approval) |
| `workflow_dispatch` `action=destroy` | destroy | destroy (requires env approval) | destroy (requires env approval) |

Wait, the `uat` and `prod` environments: set the "Required reviewers" protection rule to
turn apply/destroy into a manual invoke + approval flow. `dev` can apply directly.

All three env workflows reuse the two reference workflows via `workflow_call` — per-env
logic is limited to which backend/tfvars files and which environment gate are used.

## Customization

- **Project name / bucket names** — change `project` in `bootstrap/terraform.tfvars`,
  the `envs/*/backend.hcl` `bucket` values, and `envs/*/terraform.tfvars` `tags`.
- **Node sizing** — edit `node_groups` in each `envs/<env>/terraform.tfvars`.
- **Kubernetes version** — set `cluster_version` per env (aligned with
  [supported EKS versions](https://docs.aws.amazon.com/eks/latest/userguide/platform-versions.html)).

## Security notes

- State buckets are private, versioned and SSE-encrypted; access is restricted to the
  GitHub Actions OIDC role.
- The cluster endpoint is **private-only** (`endpoint_public_access = false`); kubectl
  requires connectivity into the VPC (VPC peering, VPN or a bastion).
- IAM policies are scoped to the services Terraform needs (`ec2`, `eks`, `iam`, `kms`,
  `logs`, `autoscaling`, `elasticloadbalancing`, state buckets, lock table).

## FAQ

- **Why separate plan vs apply workflows?** The apply job targets the GitHub
  `environment` (for approval protection); the plan job deliberately does not, so
  PR-triggered plans never stall waiting for reviewers.
- **Why per-env state buckets?** Destructive changes in one environment are isolated;
  a single shared bucket with keys would centralize risk.
- **Why DynamoDB locking instead of S3-native (`use_lockfile`)?** DynamoDB locking keeps
  all lock records in one auditable table, works across Terraform versions, and gives a
  consistent `terraform force-unlock` flow. It is explicitly chosen here, so
  `use_lockfile` is pinned to `false` in every `envs/<env>/backend.hcl`.
- **How do I add an environment (e.g. `staging`)?** Add a `envs/staging/` dir with
  tfvars + backend.hcl, add `staging` to `bootstrap/terraform.tfvars`, and add a
  caller workflow (copy `apply-dev.yml`).
