# Example: Complete

This example demonstrates how to use the Terraform AWS Yopass module to deploy
Yopass with Route53 for DNS and AWS Certificate Manager (ACM) for SSL
certificates.

## Overview

- An ACM SSL certificate is created for the website domain.
- The Yopass module is used to deploy Yopass with the provided domain name and
  SSL certificate.
- A Route53 alias record is created to point to the Yopass CloudFront
  distribution.

## Prerequisites

- An AWS account
- Terraform v0.13.0 or newer
- A domain name that you own and is managed by Route53

## Inputs

| Name                         | Description                                           | Type     | Default | Required |
|------------------------------|-------------------------------------------------------|----------|---------|:--------:|
| domain_name                  | The domain name to use for the Yopass website         | `string` | n/a     |   yes    |
| domain_parent_hosted_zone_id | The ID of the Route53 hosted zone for the domain name | `string` | n/a     |   yes    |

## Outputs

| Name                  | Description                               |
|-----------------------|-------------------------------------------|
| server_api_endpoint   | The API endpoint URL of the Yopass server |
| test_user_credentials | The credentials of the test user          |
| website_endpoint      | Address of the website_endpoint           |
