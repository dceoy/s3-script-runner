#!/usr/bin/env bash

set -euxo pipefail

IMAGE_NAME="${IMAGE_NAME:-executor-on-s3}"
IMAGE_TAG="${IMAGE_TAG:-latest}"
AWS_REGION="$(aws configure get region)"

aws ecr list-images \
  --region "${AWS_REGION}" \
  --repository-name "${IMAGE_NAME}" \
  --query 'imageIds[*].imageDigest' \
  --output text \
  | tr '\t' '\n' \
  | xargs -t -L1 -I{} aws ecr batch-delete-image \
    --region "${AWS_REGION}" \
    --repository-name "${IMAGE_NAME}" \
    --image-ids imageDigest={}
