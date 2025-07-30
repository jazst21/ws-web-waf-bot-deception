# Bot Deception - Stage 1A Configuration

This is a modified version of the bot deception infrastructure that uses **CloudFront with default TLS certificate** instead of a custom domain with ACM certificate.

## Key Differences from Original Stage 1

### ❌ Removed Components
- **ACM Certificate**: No longer requires a custom SSL certificate
- **Route53 Hosted Zone**: No longer requires a public hosted zone
- **Custom Domain**: No longer uses `*.demo.wadafa.xyz`

### ✅ New Components
- **CloudFront Distribution**: Uses AWS-managed default certificate
- **Default CloudFront Domain**: Accessible via `*.cloudfront.net` domain

## Architecture

```
Internet → CloudFront (default TLS) → ALB → EC2 → S3
```

## Benefits

1. **Simplified Setup**: No need to manage custom domains or certificates
2. **Cost Reduction**: Eliminates Route53 hosted zone costs
3. **Faster Deployment**: No DNS propagation delays
4. **Managed Security**: AWS handles certificate renewal automatically

## Access URL

After deployment, your bot deception system will be accessible at:
```
https://[distribution-id].cloudfront.net
```

The exact URL will be available in the Terraform outputs as `cloudfront_distribution_domain_name`.

## Usage

1. Deploy the infrastructure:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

2. Access the bot trapping system using the CloudFront domain name from the outputs

3. The system will still function as a bot deception system with:
   - Legitimate traffic served from EC2 instances
   - Bot detection via WAF
   - Fake webpages served from S3
   - CloudFront functions for bot redirection

## Files

- `main.tf`: Main infrastructure configuration
- `variables.tf`: Input variables (simplified)
- `outputs.tf`: Output values including CloudFront domain
- `modules/cloudfront/`: Modified CloudFront module without custom domain requirements 