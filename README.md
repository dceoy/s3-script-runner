s3-script-runner
================

Script Runner on S3

[![Lint](https://github.com/dceoy/s3-script-runner/actions/workflows/lint.yml/badge.svg)](https://github.com/dceoy/s3-script-runner/actions/workflows/lint.yml)

Installation
------------

1.  Check out the repository.

    ```sh
    $ git clone --recurse-submodules https://github.com/dceoy/s3-script-runner.git
    $ cd s3-script-runner
    ```

2.  Install [Rain](https://github.com/aws-cloudformation/rain) and set `~/.aws/config` and `~/.aws/credentials`.

3.  Deploy stacks for S3 and IAM.

    ```sh
    $ rain deploy \
        --params ProjectName=ssr-dev \
        s3-bucket-and-iam-resources.cfn.yml \
        ssr-dev-s3-bucket-and-iam-resources
    ```

4.  Deploy stacks for VPC private subnets and VPC endpoints.

    ```sh
    $ rain deploy \
        --params ProjectName=ssr-dev,NumberOfAvailabilityZones=1 \
        aws-cfn-vpc-for-slc/vpc-private-subnets-with-gateway-endpoints.cfn.yml \
        ssr-dev-vpc-private-subnets-with-gateway-endpoints
    ```

5.  Deploy stacks for Batch.

    ```sh
    $ rain deploy \
        --params ProjectName=ssr-dev,IamStackName=ssr-dev-s3-bucket-and-iam-resources,VpcStackName=ssr-dev-vpc-private-subnets-with-gateway-endpoints,NumberOfAvailabilityZones=1 \
        batch-environments-and-queues.cfn.yml ssr-dev-batch-environments-and-queues
    ```

6.  Deploy stacks for ECR and CodeBuild.

    ```sh
    $ rain deploy \
        --params ProjectName=ssr-dev,IamStackName=ssr-dev-s3-bucket-and-iam-resources \
        ecr-repository-and-codebuild-project.cfn.yml \
        ssr-dev-ecr-repository-and-codebuild-project
    ```

7.  Push the repository to CodeCommit.

8.  Register a Batch job definition.

    ```sh
    $ rain deploy \
        --params ProjectName=ssr-dev,IamStackName=ssr-dev-s3-bucket-and-iam-resources \
        batch-job-definition.cfn.yml ssr-dev-batch-job-definition
    ```

9.  Deploy stacks for VPC public subnets with NAT gateways.

    ```sh
    $ rain deploy \
        --params ProjectName=ssr-dev,VpcStackName=ssr-dev-vpc-private-subnets-with-gateway-endpoints,NumberOfAvailabilityZones=1 \
        aws-cfn-vpc-for-slc/vpc-public-subnets-with-nat-gateways.cfn.yml \
        ssr-dev-vpc-public-subnets-with-nat-gateways
    ```

Test
----

1.  Execute the test script using shUnit2.

    ```sh
    $ cd ./test
    $ ./test_batch_job.sh
    ```

2.  Remove test data on S3 and temporary data.

    ```sh
    $ ./cleanup.sh
    ```

Cleanup
-------

1.  Remove data on ECR.

    ```sh
    $ ./test/delete_ecr_images.sh
    ```

2.  Delete CloudFormation stacks.

    ```sh
    $ aws cloudformation describe-stacks \
        --query "reverse(Stacks[?starts_with(StackName, 'ssr-dev-')]|sort_by(@, &CreationTime))[].StackName" \
        --output text \
        | tr '\t' '\n' \
        | xargs -t -L1 rain rm -y
    ```
