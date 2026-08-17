# Automated Static Website Deployment

S3 + CloudFront static site, provisioned by Terraform, deployed automatically
by GitHub Actions on every push to `main`.

## Prerequisites

- An AWS account
- AWS CLI installed and configured locally (`aws configure`) - used only for
  the one-time bootstrap step below
- Terraform installed locally (v1.5+) - used for local testing before you
  wire up CI
- A GitHub repository for this project

## Step 1 - Create the Terraform state bucket (one-time, manual)

Terraform needs somewhere durable to store its state file, and it can't be
the same bucket the website lives in (chicken-and-egg problem: Terraform
would need state to know the bucket exists before it can use the bucket).
Create a small, separate bucket by hand:

```bash
aws s3api create-bucket --bucket YOUR-NAME-tf-state --region us-east-1
aws s3api put-bucket-versioning --bucket YOUR-NAME-tf-state \
  --versioning-configuration Status=Enabled
```

Then uncomment the `backend "s3"` block in `terraform/providers.tf` and fill
in that bucket name.

## Step 2 - Choose your website bucket name

Edit `terraform/variables.tf` (or pass `-var`) with a globally unique bucket
name for the site itself, e.g. `yourname-portfolio-site`.

## Step 3 - Set up IAM so GitHub Actions can deploy

The workflow uses OpenID Connect (OIDC) so GitHub can request short-lived AWS
credentials instead of you storing a permanent access key as a secret. To
set this up:

1. In AWS IAM, add GitHub as an OIDC identity provider:
   - Provider URL: `https://token.actions.githubusercontent.com`
   - Audience: `sts.amazonaws.com`
2. Create an IAM role with a trust policy that allows your specific GitHub
   repo to assume it (scope the `sub` condition to
   `repo:YOUR-GITHUB-USERNAME/YOUR-REPO-NAME:ref:refs/heads/main` so no other
   repo or branch can use it).
3. Attach a permissions policy to that role allowing: S3 (read/write on both
   the state bucket and the website bucket), CloudFront (create/manage
   distributions and invalidations), and IAM (only what's needed to manage
   the OAC resource - `iam:PassRole` isn't required here since no EC2/Lambda
   role is involved).
4. Copy the role's ARN.

*(If OIDC feels like too much for a first pass, the simpler fallback is an
IAM user with an access key stored as `AWS_ACCESS_KEY_ID` /
`AWS_SECRET_ACCESS_KEY` secrets, and swapping the "Configure AWS credentials"
step in the workflow accordingly - just know OIDC is the more current best
practice and worth mentioning in an interview.)*

## Step 4 - Add GitHub repo secrets

In your repo: **Settings → Secrets and variables → Actions**, add:

- `AWS_ROLE_ARN` - the role ARN from Step 3
- `WEBSITE_BUCKET_NAME` - the bucket name you chose in Step 2

## Step 5 - Test locally first

Before trusting the pipeline, run it by hand once so you understand what
it's doing and can catch mistakes in a synchronous, readable way:

```bash
cd terraform
terraform init
terraform plan -var="bucket_name=YOUR-CHOSEN-NAME"
terraform apply -var="bucket_name=YOUR-CHOSEN-NAME"
```

Confirm the CloudFront domain from the output actually serves the site
(CloudFront distributions take a few minutes to deploy the first time).

## Step 6 - Push to GitHub

```bash
git init
git add .
git commit -m "Automated static website deployment"
git remote add origin https://github.com/YOUR-USERNAME/YOUR-REPO.git
git push -u origin main
```

The push to `main` triggers `.github/workflows/deploy.yml`, which will:
1. Apply any Terraform changes
2. Sync `website/` to S3
3. Invalidate the CloudFront cache so changes show up immediately instead of
   waiting for the old cached version to expire

Watch it run under the **Actions** tab of your repo.

## Step 7 - Iterate

Edit anything in `website/`, commit, push - the site updates automatically.
Edit anything in `terraform/`, commit, push - the infrastructure updates
automatically.

## Cleanup

To tear everything down and avoid ongoing charges:

```bash
cd terraform
terraform destroy -var="bucket_name=YOUR-CHOSEN-NAME"
```

Then manually empty and delete the Terraform state bucket from Step 1 if you
no longer need it.
