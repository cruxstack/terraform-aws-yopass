# Terraform Module: Yopass (via AWS Serverless)

> :warning: **This module is moved to the [CruxStack organization](https://github.com/cruxstack.terraform-aws-yopass). Please switch to [`cruxstack/yopass/aws` Terraform module](https://registry.terraform.io/modules/cruxstack/yopass/aws/latest).**

This Terraform module deploys a [Yopass](https://github.com/jhaals/yopass)
server using a serverless architecture on AWS. It leverages AWS Lambda,
DynamoDB, and CloudFront to provide a highly available, scalable, and
cost-effective solution. The design adheres to a pay-per-use model.

## Features

- **Secure Secret Sharing**: Yopass is designed for secure secret sharing, and
  client-side encryption ensures your secrets remain private.
- **Serverless Deployment**: Yopass is deployed using AWS Lambda, enabling a
  highly scalable and maintenance-free setup.
- **Cost-Effective**: The pay-per-use model of AWS Lambda and DynamoDB ensures
  you only pay for what you use.
- **CloudFront Distribution**: The Yopass website is served via a CloudFront
  distribution for a fast and secure user experience globally.
- **Automated Deployment**: The entire Yopass deployment, including the server,
  website, and database, is handled by Terraform, providing an easy and repeatable deployment process.
- **User Authentication Layer**: An optional user authentication layer is
  available, securing access to the Yopass website using AWS Cognito.

## Prerequisites

- Terraform v0.13.0 or newer
- An AWS account
- Docker for building Yopass server artifact

## Usage

```hcl
module "yopass" {
  source  = "cruxstack/yopass/aws"
  version = "x.x.x"

  name                               = "yopass"
  yopass_encrypted_secret_max_length = 10000
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

In addition to the variables documented below, this module includes several
other optional variables (e.g., `name`, `tags`, etc.) provided by the
`cloudposse/label/null` module. Please refer to the [`cloudposse/label` documentation](https://registry.terraform.io/modules/cloudposse/label/null/latest) for more details on these variables.

| Name                                 | Description                                                                                                   |                 Type                 | Default  | Required |
|--------------------------------------|---------------------------------------------------------------------------------------------------------------|:------------------------------------:|:--------:|:--------:|
| `auth_cognito_idp_arn`               | ARN of the Cognito User Pool to use for authentication. Only appliable if `auth_enabled` is `true`.           |                string                |   null   |    No    |
| `auth_cognito_idp_client_id`         | Client ID of the Cognito User Pool to use for authentication. Only appliable if `auth_enabled` is `true`.     |                string                |   null   |    No    |
| `auth_cognito_idp_client_scopes`     | Client scopes of the Cognito User Pool to use for authentication. Only appliable if `auth_enabled` is `true`. |             list(string)             |    []    |    No    |
| `auth_cognito_idp_client_secret`     | Client secret of the Cognito User Pool to use for authentication. Only appliable if `auth_enabled` is `true`. |                string                |   null   |    No    |
| `auth_cognito_idp_domain`            | Domain of the Cognito User Pool to use for authentication. Only appliable if `auth_enabled` is `true`.        |                string                |   null   |    No    |
| `auth_cognito_idp_jwks`              | JWKS of the Cognito User Pool to use for authentication. Only appliable if `auth_enabled` is `true`.          | object({ keys = list(map(string)) }) |   null   |    No    |
| `auth_enabled`                       | Whether to enable authentication power by Cognito User Pool.                                                  |                 bool                 |  false   |    No    |
| `aws_account_id`                     | The AWS account ID that the module will be deployed.                                                          |                string                |    ""    |    No    |
| `aws_region_name`                    | The AWS region name where the module will be deployed.                                                        |                string                |    ""    |    No    |
| `server_waf_acl_name`                | Name of the WAF ACL to associate with the API Gateway.                                                        |                string                |    ""    |    No    |
| `website_certificate_arn`            | ARN of the ACM certificate for the domain name.                                                               |                string                |   None   |   Yes    |
| `website_domain_name`                | Domain name for Yopass website.                                                                               |                string                |   None   |   Yes    |
| `website_waf_acl_name`               | Name of the WAF ACL to associate with the CloudFront distribution.                                            |                string                |    ""    |    No    |
| `yopass_encrypted_secret_max_length` | Maximum length of encrypted secrets.                                                                          |                number                |  10000   |    No    |
| `yopass_version`                     | Version of Yopass to deploy.                                                                                  |                string                | "latest" |    No    |

## Outputs

| Name                                | Description                                                                   |
|-------------------------------------|-------------------------------------------------------------------------------|
| `server_apigw_id`                   | The ID of the Yopass server API Gateway.                                      |
| `server_apigw_url`                  | The URL of the Yopass server API Gateway.                                     |
| `website_cloudfront_domain_name`    | The domain name of the CloudFront distribution serving the Yopass website.    |
| `website_cloudfront_hosted_zone_id` | The hosted zone id of the CloudFront distribution serving the Yopass website. |

## Contributing

We welcome contributions to this project. For information on setting up a
development environment and how to make a contribution, see [CONTRIBUTING](./CONTRIBUTING.md)
documentation.
