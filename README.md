# Terraform Module: Yopass (via AWS Serverless)

This Terraform module deploys a [Yopass](https://github.com/jhaals/yopass)
server in a serverless architecture using AWS Lambda and DynamoDB. Yopass is a
service for generating and sharing secrets in a secure manner. You can visit the
[demo website](https://yopass.se/) to see Yopass in action.

## Prerequisites

- Terraform v0.13.0 or newer
- An AWS account
- Docker for building Yopass server artifact

## Usage

```hcl
module "yopass" {
  source = "sgtoj/yopass/aws"

  name                               = "yopass"
  yopass_version                     = "latest"
  yopass_encrypted_secret_max_length = 10000
}
```

## Requirements

- Terraform 0.13.0 or later
- AWS provider 5.0.0 or later
- Docker installed and running on the machine where Terraform is executed

## Inputs

| Name                                 | Description                                             |  Type  | Default  | Required |
|--------------------------------------|---------------------------------------------------------|:------:|:--------:|:--------:|
| `yopass_encrypted_secret_max_length` | The maximum length of the encrypted secrets.            |  int   |  10000   |    no    |
| `yopass_version`                     | Version of Yopass to deploy.                            | string | "latest" |    no    |
| `aws_account_id`                     | The AWS account ID that the module will be deployed in. | string |    ""    |    no    |
| `aws_region_name`                    | The AWS region name where the module will be deployed.  | string |    ""    |    no    |

### Note

This module uses the `cloudposse/label/null` module for naming and tagging
resources. As such, it also includes a `context.tf` file with additional
optional variables you can set. Refer to the [`cloudposse/label` documentation](https://registry.terraform.io/modules/cloudposse/label/null/latest)
for more details on these variables.

## Outputs

| Name                      | Description                                                             |
|---------------------------|-------------------------------------------------------------------------|
| `lambda_fn_arn`           | The ARN of the AWS Lambda function running the Yopass server.           |
| `lambda_fn_execution_url` | The URL for invoking the AWS Lambda function running the Yopass server. |

## Contributing

We welcome contributions to this project. For information on setting up a
development environment and how to make a contribution, see [CONTRIBUTING](./CONTRIBUTING.md)
documentation.
