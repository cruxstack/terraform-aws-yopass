# Terraform Module Example

## Complete

This example demonstrates how to use the Terraform AWS Yopass module to deploy
Yopass with Route53 for DNS and AWS Certificate Manager (ACM) for SSL
certificates.

## Overview

- An ACM SSL certificate is created for the website domain.
- The Yopass module is used to deploy Yopass with the provided domain name and
  SSL certificate.
- A Route53 alias record is created to point to the Yopass CloudFront
  distribution.
