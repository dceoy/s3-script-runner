s3-script-runner
================

Script Runner on S3

[![Lint](https://github.com/dceoy/s3-script-runner/actions/workflows/lint.yml/badge.svg)](https://github.com/dceoy/s3-script-runner/actions/workflows/lint.yml)

Installation
------------

1.  Check out the repository.

    ```sh
    $ git clone --recurse-submodules git@github.com:dceoy/s3-script-runner.git
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

5.  Deploy stacks for VPC public subnets with NAT gateways.

    ```sh
    $ rain deploy \
        --params ProjectName=ssr-dev,VpcStackName=ssr-dev-vpc-private-subnets-with-gateway-endpoints,NumberOfAvailabilityZones=1 \
        aws-cfn-vpc-for-slc/vpc-public-subnets-with-nat-gateways.cfn.yml \
        ssr-dev-vpc-public-subnets-with-nat-gateways
    ```

6.  Deploy stacks for Batch.

    ```sh
    $ rain deploy \
        --params ProjectName=ssr-dev,IamStackName=ssr-dev-s3-bucket-and-iam-resources,VpcStackName=ssr-dev-vpc-private-subnets-with-gateway-endpoints,NumberOfAvailabilityZones=1 \
        batch-environments-and-queues.cfn.yml ssr-dev-batch-environments-and-queues
    ```

7.  Deploy stacks for ECR and CodeBuild.

    ```sh
    $ rain deploy \
        --params ProjectName=ssr-dev,IamStackName=ssr-dev-s3-bucket-and-iam-resources \
        ecr-repository-and-codebuild-project.cfn.yml \
        ssr-dev-ecr-repository-and-codebuild-project
    ```
