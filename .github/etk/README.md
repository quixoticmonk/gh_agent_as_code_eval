# agent-as-judge-eval pipeline setup

One-time repo configuration for `.github/workflows/agent-as-judge-eval.yml`.

## Required secrets

| Secret               | Purpose                                                             |
| --------------------- | -------------------------------------------------------------------- |
| `AWS_ETK_ROLE_ARN`    | IAM role the workflow assumes via GitHub OIDC to get session creds. Must trust `token.actions.githubusercontent.com` scoped to this repo, and be allowed `execute-api:Invoke` on the ETK API, `s3:PutObject`/`GetObject` on `ETK_RESULTS_BUCKET`, and `ssm:GetParameter` if `GEN_AI_ETK_API_URL` isn't set directly. |

## Required/optional repo variables (Settings → Secrets and variables → Actions → Variables)

| Variable                     | Required | Default                                     | Purpose                                                                 |
| ----------------------------- | -------- | -------------------------------------------- | ------------------------------------------------------------------------ |
| `ETK_RESULTS_BUCKET`          | yes      | —                                             | S3 bucket the diff + requirement doc are uploaded to.                    |
| `AWS_REGION`                  | no       | `us-east-1`                                  | Region for the IAM role session and ETK deployment.                      |
| `GEN_AI_ETK_API_URL`          | no       | resolved from SSM `/genai-<project>/restApiEndpoint` | genai-ETK REST API URL (this is the CLI's actual required env var — there is no `ETK_ENDPOINT`). |
| `ETK_PROJECT_NAME`            | no       | `etk`                                        | Used only for the SSM fallback lookup above.                             |
| `PYTHON_STYLE_GUIDE_PATH`     | no       | `.github/etk/requirements/python-style-guide.md` | Path in this repo to the style guide uploaded as the requirement doc.    |
| `ETK_CONFIG_TEMPLATE_S3_URI`  | no       | —                                             | If set, `scorer-config.json`/`test-cases.json` are downloaded from `<uri>/scorer-config.json` and `<uri>/test-cases.json` instead of the in-repo templates under `.github/etk/`. |

## What the pipeline does per PR

1. Assumes `AWS_ETK_ROLE_ARN` via OIDC for session credentials.
2. Resolves `GEN_AI_ETK_API_URL` (repo variable or SSM) and `AWS_REGION`.
3. Installs the `genai-etk` CLI (**placeholder step — replace with a real install**).
4. Diffs the PR's base..head and uploads it, plus the Python style guide, to
   `s3://$ETK_RESULTS_BUCKET/evaluation/agent-as-judge/<repo>/pr-<number>/artifacts/diff/` and
   `.../<repo>/requirements/` respectively.
5. Builds `scorer-config.json`/`test-cases.json` pointing at those S3 keys.
6. Creates (or reuses) MLflow experiment `agent-as-judge-python-eval-<repo>-pr-<number>`.
7. Submits a `SCORE` job to the `agent-as-judge` evaluator against that experiment, polls
   `eval job get` until `SUCCESS`/`FAILURE`/`PARTIAL_FAILURE`, and fetches the report.
8. Posts (and updates on re-runs) a PR comment with the job status and per-test-case results,
   then fails the workflow if the job didn't end in `SUCCESS`.

## Known upstream quirks (see `agent-as-judge-known-bugs.md` in this workspace)

- Every test case must have a non-null `output` field (`""` is fine) — the template already sets
  this — otherwise the SCORE job silently scores 0 items.
- The evaluator can non-deterministically fail with a permission error reading its own
  downloaded artifacts on identical input/config. Re-running the workflow is the current
  workaround; this is an upstream bug, not a pipeline misconfiguration.
