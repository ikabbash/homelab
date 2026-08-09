# Renovate
Homelab uses [Renovate](https://docs.renovatebot.com/) to keep deployments up-to-date: Helm chart versions (both under Argo CD and inside Terraform modules), container image tags in plain manifests, and Terraform provider/version constraints. It runs self-hosted via a Kubernetes CronJob rather than the Mend-hosted GitHub App, see [Renovate's Kubernetes self-hosting example](https://docs.renovatebot.com/examples/self-hosting/#kubernetes) for the general setup this follows.

Config is split into two layers. Global config tells the CLI *where* to run, platform, `repositories`, `onboarding: false` since the repo-level config is committed up front instead of letting Renovate open an onboarding PR. Repo config (`renovate.json`, committed to the repo root) tells Renovate *what* to update and how, managers, grouping, PR limits, this is the file that actually matters day to day.

## Managers
Renovate uses "managers" to know which files to look at and how to parse them. Some ship with sensible defaults, some don't.
- [`argocd`](https://docs.renovatebot.com/modules/manager/argocd/) reads Helm sources (`chart:`/`targetRevision:`) inside Argo CD `Application` manifests and has no default file pattern, it has to be told where to look: `argocd/apps/*.yaml`.
- [`kubernetes`](https://docs.renovatebot.com/modules/manager/kubernetes/) reads `image:` tags in plain manifests, also no default, scoped here to `argocd/k8s/**/deployment.yaml` specifically (not the database `statefulset.yaml` files, which are managed by hand).
- [`terraform`](https://docs.renovatebot.com/modules/manager/terraform) reads `required_providers`/`required_version` blocks natively and *does* ship with a default (`**/*.tf`), which matters, see below.
- [`custom.regex`](https://docs.renovatebot.com/configuration-options/#custommanagers) is a regex-based manager for anything the built-ins can't see, used here for `chart_version` in the Terraform phases.

Setting a manager's `managerFilePatterns` doesn't replace its built-in default, it **extends** it. This is documented but easy to miss: "Renovate will extend the existing managerFilePatterns... the patterns are additive. If a manager matches a file that you don't want it to, ignore it using the `ignorePaths` configuration option." `argocd` and `kubernetes` have no default, so our patterns became the only rule and worked as expected. `terraform` already defaults to `**/*.tf`, so trying to narrow it to `main.tf` did nothing, the union of "everything" and "just main.tf" is still "everything." The actual fix is `ignorePaths`, which excludes files repo-wide regardless of manager:

```json
"ignorePaths": ["**/providers.tf"]
```

The native `terraform` manager only reads literal values inside `resource "helm_release"` blocks. In this repo those resources live inside each phase's `./modules/*`, and the root `main.tf` just passes `chart_version` in as a module variable, a variable reference isn't something Renovate can read a version out of. A `customManagers` (regex) entry fills the gap, triggered by a comment placed directly above the line:

```hcl
# renovate: datasource=helm depName=cilium registryUrl=https://helm.cilium.io/
chart_version = "1.19.6"
```

Every `module` block that sets `chart_version` needs this comment, the chart name and repo URL have to match what's actually declared in that module's `helm_release` resource.

## Configuration decisions
`helm`/`kubernetes` Terraform providers and the `required_version` constraint are declared almost identically in every phase. Left alone that's up to 15 near-duplicate PRs for what's functionally one change, so they're grouped into a single PR via `packageRules` + shared `groupName`. Vault (phase03 only) and the Authentik provider (phase05's `authentik-configs` module) aren't part of this group since they don't repeat across phases, they get their own PRs automatically, no extra config needed.

Renovate defaults to `prHourlyLimit: 2` (a hardcoded default, not from a preset), scoped to a real clock hour rather than a rolling window. It's meant to stop a huge PR flood when onboarding Renovate onto an org with hundreds of existing repos. For a single homelab repo bootstrapping ~9 branches at once, it's the wrong default, so both limits are disabled: `prHourlyLimit: 0`, `prConcurrentLimit: 0`.

`.terraform.lock.hcl` exists per phase and gets refreshed on a weekly schedule, scoped explicitly to `matchManagers: ["terraform"]` so it can never touch anything else, even if another manager with lock-file support gets added later.

Renovate maintains a single tracking issue, the [Dependency Dashboard](https://docs.renovatebot.com/key-concepts/dashboard/), listing every dependency it manages, what's pending, and why something might be skipped. This is the first place to check when a PR you expected didn't show up.

## Testing
Set `RENOVATE_DRY_RUN` on the CronJob's pod spec before letting Renovate touch anything for real.

There are three levels:
- `extract` just shows what it parsed, no version lookups.
- `lookup` parses and checks for new versions, logging what it found
- `full` runs the entire pipeline, including simulating branch/PR creation and diffs, but makes no git pushes and opens nothing on GitHub.
  - `full` is the closest thing to "show me every PR before it's real."