#!/usr/bin/env bash

set -euxo pipefail

IMAGE_NAME="${IMAGE_NAME:-executor-on-s3}"
IMAGE_TAG="${IMAGE_TAG:-latest}"
AWS_ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
AWS_REGION="$(aws configure get region)"
ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

aws ecr list-images \
  --repository-name "${IMAGE_NAME}" \
  --region "${AWS_REGION}" \
  --query 'imageIds[*].imageDigest' \
  --output text \
  | tr '\t' '\n' \
  | xargs -t -L1 -I{} aws ecr batch-delete-image \
    --repository-name "${IMAGE_NAME}" \
    --image-ids imageDigest={} \
    --region "${AWS_REGION}"
