#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

BUCKET="frontend"
USER_NAME="frontend-deployer"
POLICY_NAME="FrontendDeploy"
POLICY_ARN="arn:aws:iam::000000000000:policy/${POLICY_NAME}"

echo "==> Creating bucket"
awslocal s3 mb "s3://${BUCKET}"

echo "==> Uploading website"
awslocal s3 sync ./frontend "s3://${BUCKET}"
awslocal s3 website "s3://${BUCKET}/" --index-document index.html

echo "==> Creating IAM user"
awslocal iam create-user --user-name "$USER_NAME" > /dev/null

echo "==> Creating and attaching policy"
awslocal iam create-policy \
  --policy-name "$POLICY_NAME" \
  --policy-document file://deploy-policy.json > /dev/null
awslocal iam attach-user-policy \
  --user-name "$USER_NAME" \
  --policy-arn "$POLICY_ARN"

echo "==> Creating access keys"
read -r KEY_ID SECRET < <(awslocal iam create-access-key \
  --user-name "$USER_NAME" \
  --query 'AccessKey.[AccessKeyId,SecretAccessKey]' \
  --output text)

cat > deployer.env << KEYS
export AWS_ACCESS_KEY_ID=$KEY_ID
export AWS_SECRET_ACCESS_KEY='$SECRET'
KEYS
chmod 600 deployer.env

echo "Done. Website: http://${BUCKET}.s3-website.localhost.localstack.cloud:4566/"
echo "Deployer credentials saved in deployer.env"
