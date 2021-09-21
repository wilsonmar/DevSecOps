# ./ssl_cert_req.tf within https://github.com/wilsonmar/DevSecOps/aws
# Gets an SSL cert, issue a CLI call to get the cert. RE-requests just return the ARN
# Based on https://github.com/divgo/terraform/blob/master/aws_ssl_static_website/main.tf

data "external" "cert_request" {
    program = ["bash", "./ssl_cert_req.sh"]
    query = {
        site_name = "${var.site_name}"
    }
}

module "dns_domain" {
    source = "./dns_domain"
    domain_parts = "${split(".",var.site_name)}"
    parts_count = "${length(split(".",var.site_name))}"
}

# s3 Bucket with Website settings
resource "aws_s3_bucket" "site_bucket" {
    bucket = "${var.site_name}"
    acl = "public-read"

    website {
        index_document = "index.html"
        error_document = "error.html"
    }
}

# Route53 Domain Name
resource "aws_route53_zone" "site_zone" {
    name = "${module.dns_domain.root_dns}"
}
resource "aws_route53_record" "site_ns" {
    zone_id = "${aws_route53_zone.site_zone.zone_id}"
    name = "${module.dns_domain.root_dns}"
    type = "NS"
    ttl = "30"
    records = [
        "${aws_route53_zone.site_zone.name_servers.0}",
        "${aws_route53_zone.site_zone.name_servers.1}",
        "${aws_route53_zone.site_zone.name_servers.2}",
        "${aws_route53_zone.site_zone.name_servers.3}"
    ]
}
resource "aws_route53_record" "site_cname_static" {
    zone_id = "${aws_route53_zone.site_zone.zone_id}"
    name = "static.${module.dns_domain.root_dns}"
    type = "CNAME"
    ttl = "30"
    records = [
        "${aws_s3_bucket.site_bucket.bucket_domain_name}"
    ]
}
resource "aws_route53_record" "site_cname" {
    zone_id = "${aws_route53_zone.site_zone.zone_id}"
    name = "${var.site_name}"
    type = "CNAME"
    ttl = "30"
    records = [
        "${aws_cloudfront_distribution.site_distribution.domain_name}"
    ]
}

# cloudfront distribution
resource "aws_cloudfront_distribution" "site_distribution" {
    origin {
        domain_name = "${aws_s3_bucket.site_bucket.bucket_domain_name}"
        origin_id = "${var.site_name}-origin"
    }

    enabled = true
    aliases = ["${var.site_name}"]
    price_class = "PriceClass_100"

    default_cache_behavior {
        allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
        cached_methods   = ["GET", "HEAD"]
        target_origin_id = "${var.site_name}-origin"

        forwarded_values {
            query_string = true
            cookies {
                forward = "all"
            }
        }
        viewer_protocol_policy = "https-only"
        min_ttl                = 0
        default_ttl            = 1000
        max_ttl                = 86400
    }
    restrictions {
        geo_restriction {
            restriction_type = "none"
        }
    }
    viewer_certificate {
        acm_certificate_arn = "${data.external.cert_request.result.CertificateArn}"
        ssl_support_method  = "sni-only"
        # See https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_distribution
        cloudfront_default_certificate = false
        minimum_protocol_version = "TLSv1.2_2021" # set manually since TF default "TLSv1" is not secure for vip in ssl_support_method
           # TLSv1.2_2019 and TLSv1.2_2021 and TLSv1.1_2016
           # TLSv1.3 waiting for https://github.com/hashicorp/terraform-provider-aws/issues/15194
           # TLSv1.3 avail. per https://aws.amazon.com/about-aws/whats-new/2020/09/cloudfront-tlsv1-3-support/
    }
}