#!/usr/bin/env bash

set -eu

PROJECT_NAME="${PROJECT_NAME:-ssr-dev}"
IMAGE_NAME="${IMAGE_NAME:-executor-on-s3}"
AWS_ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
MOUNT_S3_BUCKET="${MOUNT_S3_BUCKET:-${PROJECT_NAME}-io-${AWS_ACCOUNT_ID}}"
TIMEOUT_SECONDS="${TIMEOUT_SECONDS:-3600}"
# shellcheck disable=SC2016
BATCH_JOB_DEFINITION="$( \
  aws cloudformation describe-stacks \
    --query 'Stacks[0].Outputs[?OutputKey==`BatchJobDefinition`].OutputValue' \
    --output text \
    --stack-name ssr-dev-batch-job-definition \
    | cut -d / -f 2
)"
BATCH_SUBMIT_JOB_JSON="${BATCH_SUBMIT_JOB_JSON:-batch.submit-job.j2.json}"
TEST_SCRIPT="${TEST_SCRIPT:-example_commands.sh}"
TEST_OUTPUT_FILE="$(basename "${TEST_SCRIPT}").output.txt"
PLATFORM="${PLATFORM:-ec2}"
TMP_BATCH_SUBMIT_JOB_JSON="tmp.${BATCH_JOB_DEFINITION%:*}.${BATCH_SUBMIT_JOB_JSON##*/}"
TMP_BATCH_SUBMIT_JOB_OUTPUT_JSON="${TMP_BATCH_SUBMIT_JOB_JSON%.*}.output.json"

set +e

echo "PROJECT_NAME:                   ${PROJECT_NAME}"
echo "IMAGE_NAME:                     ${IMAGE_NAME}"
echo "AWS_ACCOUNT_ID:                 ${AWS_ACCOUNT_ID}"
echo "TIMEOUT_SECONDS:                ${TIMEOUT_SECONDS}"
echo "BATCH_JOB_DEFINITION:           ${BATCH_JOB_DEFINITION}"
echo "BATCH_SUBMIT_JOB_JSON:          ${BATCH_SUBMIT_JOB_JSON}"
echo "TEST_SCRIPT:                    ${TEST_SCRIPT}"

oneTimeSetUp() {
  aws s3 cp "${TEST_SCRIPT}" "s3://${MOUNT_S3_BUCKET}/tmp/${IMAGE_NAME}/${TEST_SCRIPT}"
}

# oneTimeTearDown() {
#   rm -f tmp.*.json
# }

testBatchJobSubmit() {
  jq ".jobDefinition=\"${BATCH_JOB_DEFINITION}\"" < "${BATCH_SUBMIT_JOB_JSON}" \
    | jq ".jobQueue=\"${PROJECT_NAME}-batch-job-queue-${PLATFORM}-intel-spot\"" \
    | jq ".containerOverrides.command[0]=\"/mnt/s3/tmp/${IMAGE_NAME}/${TEST_SCRIPT}\"" \
    | jq ".containerOverrides.command[1]=\"/mnt/s3/tmp/${IMAGE_NAME}/${TEST_OUTPUT_FILE}\"" \
    > "${TMP_BATCH_SUBMIT_JOB_JSON}"
  aws batch submit-job --cli-input-json "file://${TMP_BATCH_SUBMIT_JOB_JSON}" \
    | tee "${TMP_BATCH_SUBMIT_JOB_OUTPUT_JSON}"
  assertEquals 'aws batch submit-job' 0 "${PIPESTATUS[0]}"
}

testBatchJobStatus() {
  end_seconds=$((SECONDS + TIMEOUT_SECONDS))
  ji=$(jq -r '.jobId' < "${TMP_BATCH_SUBMIT_JOB_OUTPUT_JSON}")
  [[ -n "${ji}" ]] || exit 1
  js=''
  while [[ ${SECONDS} -lt ${end_seconds} ]]; do
    aws batch describe-jobs --jobs "${ji}" > "tmp.${ji}.batch.describe-jobs.output.json"
    js=$(jq -r '.jobs[0].status' < "tmp.${ji}.batch.describe-jobs.output.json")
    [[ -n "${js}" ]] || exit 1
    if [[ "${js}" == 'SUCCEEDED' ]] || [[ "${js}" == 'FAILED' ]]; then
      break
    fi
    sleep 10
  done
  assertEquals 'aws batch describe-jobs' 'SUCCEEDED' "${js}"
}

testBatchJobOutput() {
  aws s3 cp \
    "s3://${MOUNT_S3_BUCKET}/tmp/${IMAGE_NAME}/${TEST_OUTPUT_FILE}" \
    "tmp.${IMAGE_NAME}.${TEST_OUTPUT_FILE}"
  assertEquals 'aws s3 cp' 0 "${?}"
  assertTrue 'aws s3 cp' "[[ -s 'tmp.${IMAGE_NAME}.${TEST_OUTPUT_FILE}' ]]"
}

# shellcheck disable=SC1091
. shunit2
