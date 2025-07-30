# CloudWatch Log Group for WAF
resource "aws_cloudwatch_log_group" "waf" {
  name              = "aws-waf-logs-bot-deception"
  retention_in_days = 7

  tags = {
    Name = "Bot Trapper WAF Logs"
  }
}

# IP Sets
resource "aws_wafv2_ip_set" "allowed_ips" {
  name  = "bot-deception-allowed-ips"
  scope = "CLOUDFRONT"

  ip_address_version = "IPV4"
  addresses          = []

  tags = {
    Name = "Bot Trapper Allowed IPs"
  }
}

resource "aws_wafv2_ip_set" "blocked_ips" {
  name  = "bot-deception-blocked-ips"
  scope = "CLOUDFRONT"

  ip_address_version = "IPV4"
  addresses          = []

  tags = {
    Name = "Bot Trapper Blocked IPs"
  }
}

# WAF Web ACL
resource "aws_wafv2_web_acl" "main" {
  name  = "bot-deception-web-acl"
  scope = "CLOUDFRONT"

  default_action {
    allow {}
  }

  # Rule 1: Block IPs in blocked IP set
  rule {
    name     = "BlockedIPsRule"
    priority = 1

    action {
      block {}
    }

    statement {
      ip_set_reference_statement {
        arn = aws_wafv2_ip_set.blocked_ips.arn
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                 = "BlockedIPsRule"
      sampled_requests_enabled    = true
    }
  }

  # Rule 2: Allow IPs in allowed IP set
  rule {
    name     = "AllowedIPsRule"
    priority = 2

    action {
      allow {}
    }

    statement {
      ip_set_reference_statement {
        arn = aws_wafv2_ip_set.allowed_ips.arn
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                 = "AllowedIPsRule"
      sampled_requests_enabled    = true
    }
  }

  # Rule 3: Rate limiting
  rule {
    name     = "RateLimitRule"
    priority = 3

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = 3000
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                 = "RateLimitRule"
      sampled_requests_enabled    = true
    }
  }

  # Rule 4: AWS Managed Core Rule Set
  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 4

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                 = "AWSManagedRulesCommonRuleSet"
      sampled_requests_enabled    = true
    }
  }

  # Rule 5: Bot Control Rule Group
  rule {
    name     = "AWSManagedRulesBotControlRuleSet"
    priority = 5

    override_action {
      count {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesBotControlRuleSet"
        vendor_name = "AWS"

        managed_rule_group_configs {
          aws_managed_rules_bot_control_rule_set {
            inspection_level = "TARGETED"
          }
        }

        scope_down_statement {
          and_statement{
            statement{
                not_statement {
                    statement {
                        byte_match_statement {
                            search_string = ".css"
                            field_to_match {
                            uri_path {}
                            }
                            text_transformation {
                            priority = 0
                            type     = "LOWERCASE"
                            }
                            positional_constraint = "ENDS_WITH"
                        }
                    }
                }
            }
            statement {
                not_statement {
                    statement {
                        byte_match_statement {
                            search_string = ".js"
                            field_to_match {
                            uri_path {}
                            }
                            text_transformation {
                            priority = 0
                            type     = "LOWERCASE"
                            }
                            positional_constraint = "ENDS_WITH"
                        }
                    }
                }
            }
            statement {
                not_statement {
                    statement {
                        byte_match_statement {
                            search_string = ".jpg"
                            field_to_match {
                            uri_path {}
                            }
                            text_transformation {
                            priority = 0
                            type     = "LOWERCASE"
                            }
                            positional_constraint = "ENDS_WITH"
                        }
                    }
                }
            }
            statement {
                not_statement {
                    statement {
                        byte_match_statement {
                            search_string = ".png"
                            field_to_match {
                            uri_path {}
                            }
                            text_transformation {
                            priority = 0
                            type     = "LOWERCASE"
                            }
                            positional_constraint = "ENDS_WITH"
                        }
                    }
                }
            }
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                 = "AWSManagedRulesBotControlRuleSet"
      sampled_requests_enabled    = true
    }
  }

  # Rule 6: Challenge rule for absent token
  rule {
    name     = "TokenAbsentChallengeRule"
    priority = 6

    action {
      challenge {}
    }

    statement {
      label_match_statement {
        scope = "LABEL"
        key   = "awswaf:managed:token:absent"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                 = "TokenAbsentChallengeRule"
      sampled_requests_enabled    = true
    }
  }

  # Rule 7: Custom rule to add header for detected bots
  rule {
    name     = "BotDetectedHeaderRule"
    priority = 7

    action {
      count {
        custom_request_handling {
          insert_header {
            name  = "targeted-bot-detected"
            value = "true"
          }
        }
      }
    }

    statement {
      label_match_statement {
        scope = "NAMESPACE"
        key   = "awswaf:managed:aws:bot-control:targeted:"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                 = "BotDetectedHeaderRule"
      sampled_requests_enabled    = true
    }
  }

  tags = {
    Name = "Bot Trapper Web ACL"
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                 = "BotTrapperWebACL"
    sampled_requests_enabled    = true
  }
}

# WAF Logging Configuration
resource "aws_wafv2_web_acl_logging_configuration" "main" {
  resource_arn            = aws_wafv2_web_acl.main.arn
  log_destination_configs = [aws_cloudwatch_log_group.waf.arn]

}
