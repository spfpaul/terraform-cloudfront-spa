locals {
    s3_origin_id = "myS3Origin"
    s3_origin_bucket_name = "tf-cloudfront-spa-933673036381"
    logging_bucket_name = "cloudfront-933673036381.s3.amazonaws.com"
    logging_bucket_prefix = "cf-standard-logs"
    domain_name = "tfspa.pengfesh.myinstance.com"
    acm_arn = "arn:aws:acm:us-east-1:933673036381:certificate/a527572e-1d40-4bcd-9e06-e9f2be549d54"
  }

resource "aws_s3_bucket" "s3_bucket" {
  bucket        = local.s3_origin_bucket_name
  acl           = "private"
  force_destroy = true

  tags = {
    Name = "Terraform CloudFront SPA"
  }
}

resource "aws_cloudfront_origin_access_identity" "s3_oai" {
    comment = "Terraform CloudFront SPA OAI"
}

resource "aws_cloudfront_function" "function_spa" {
  name    = "terraform-cloudfront-spa"
  runtime = "cloudfront-js-1.0"
  comment = "Terraform CloudFront SPA"
  publish = true
  code    = file("../function/viewer-request.js")
}

resource "aws_cloudfront_distribution" "s3_distribution" {
  aliases = [local.domain_name]

  enabled             = true
  is_ipv6_enabled     = true
  retain_on_delete    = false
  price_class         = "PriceClass_All"
  comment             = "Terraform CloudFront SPA"
  default_root_object = "index.html"

  logging_config {
    include_cookies = false
    bucket          = local.logging_bucket_name
    prefix          = local.logging_bucket_prefix
  }

  origin {
    domain_name = aws_s3_bucket.s3_bucket.bucket_regional_domain_name
    origin_id   = local.s3_origin_id

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.s3_oai.cloudfront_access_identity_path
    }
  }

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.s3_origin_id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
    compress               = true
    viewer_protocol_policy = "redirect-to-https"

    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.function_spa.arn
    }
  }

  # Cache behavior with precedence 0
  ordered_cache_behavior {
    path_pattern     = "/content/immutable/*"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = local.s3_origin_id

    forwarded_values {
      query_string = false
      headers      = ["Origin"]

      cookies {
        forward = "none"
      }
    }

    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 31536000
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags = {
    Environment = "production"
  }

  viewer_certificate {
    acm_certificate_arn = local.acm_arn
    ssl_support_method  = "sni-only"
  }
}