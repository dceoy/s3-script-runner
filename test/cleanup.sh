#!/usr/bin/env bash

set -euxo pipefail

PROJECT_NAME="${PROJECT_NAME:-ssr-dev}"
IMAGE_NAME="${IMAGE_NAME:-executor-on-s3}"
AWS_ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
MOUNT_S3_BUCKET="${MOUNT_S3_BUCKET:-${PROJECT_NAME}-io-${AWS_ACCOUNT_ID}}"

aws s3 rm --recursive "s3://${MOUNT_S3_BUCKET}/tmp/${IMAGE_NAME}/" || :
aws s3api list-object-versions \
  --bucket "${MOUNT_S3_BUCKET}" \
  --prefix "tmp/${IMAGE_NAME}/" \
  | jq -rc '.Versions[], .DeleteMarkers[] | .Key, .VersionId' \
  | xargs -L2 bash -xc \
    "aws s3api delete-object --bucket ${MOUNT_S3_BUCKET} --key \${0} --version-id \${1}" || :

cd "$(dirname "${0}")" && rm -f tmp.*
