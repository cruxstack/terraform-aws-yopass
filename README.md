# Terraform Module: Yopass (via AWS Serverless)


This Terraform module deploys a [Yopass](https://github.com/jhaals/yopass)
server using a serverless architecture on AWS. By leveraging AWS Lambda,
DynamoDB, and CloudFront, this module allows you to run Yopass in a highly
available, scalable, and cost-effective manner, adhering to a pay-per-use model.

[Yopass](https://github.com/jhaals/yopass) is an open-source project for
generating and sharing secrets securely. It provides an intuitive interface for
users to generate random secrets or upload their own, and securely share them
with others. Check out the [demo website](https://yopass.se/) to see Yopass in
action.

## Prerequisites

- Terraform v0.13.0 or newer
- An AWS account
- Docker for building Yopass server artifact

## Usage

```hcl
module "yopass" {
  source = "sgtoj/yopass/aws"

  name                               = "yopass"
  yopass_encrypted_secret_max_length = 10000
  yopass_version                     = "latest"
  website_domain_name                = "yopass.example.com"
  website_certificate_arn            = "arn:aws:acm:us-east-1:123456789012:certificate/12345678-1234-1234-1234-123456789012"
}
```

## Requirements

- Terraform 0.13.0 or later
- AWS provider
- Docker provider
- Docker installed and running on the machine where Terraform is executed

## Inputs

| Name                                 | Description                                                      |  Type  | Default  | Required |
|--------------------------------------|------------------------------------------------------------------|:------:|:--------:|:--------:|
| `yopass_encrypted_secret_max_length` | The maximum length of the encrypted secrets.                     | number |  10000   |    no    |
| `yopass_version`                     | Version of Yopass to deploy.                                     | string | "latest" |    no    |
| `website_domain_name`                | Domain name for Yopass website.                                  | string |    ""    |   yes    |
| `website_certificate_arn`            | ARN of the ACM certificate for the domain name.                  | string |    ""    |   yes    |
| `website_waf_acl_id`                 | ID of the WAF ACL to associate with the CloudFront distribution. | string |    ""    |    no    |
| `aws_account_id`                     | The AWS account ID that the module will be deployed in.          | string |    ""    |    no    |
| `aws_region_name`                    | The AWS region name where the module will be deployed.           | string |    ""    |    no    |

### Note

This module uses the `cloudposse/label/null` module for naming and tagging
resources. As such, it also includes a `context.tf` file with additional
optional variables you can set. Refer to the [`cloudposse/label` documentation](https://registry.terraform.io/modules/cloudposse/label/null/latest)
for more details on these variables.

## Outputs

| Name                                | Description                                                                   |
|-------------------------------------|-------------------------------------------------------------------------------|
| `server_apigw_url`                  | The URL of the Yopass server API Gateway.                                     |
| `website_cloudfront_domain_name`    | The domain name of the CloudFront distribution serving the Yopass website.    |
| `website_cloudfront_hosted_zone_id` | The hosted zone id of the CloudFront distribution serving the Yopass website. |

## Contributing

We welcome contributions to this project. For information on setting up a
development environment and how to make a contribution, see [CONTRIBUTING](./CONTRIBUTING.md)
documentation.
