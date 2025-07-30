import json
import boto3
import os
import random
from datetime import datetime
from botocore.config import Config

def lambda_handler(event, context):
    """
    Lambda function to generate fake webpages using Bedrock API
    and upload them to S3 bucket
    """
    
    bucket_name = os.environ['S3_BUCKET_NAME']
    
    # Configure timeout settings for AWS clients
    config = Config(
        read_timeout=300,  # 5 minutes
        connect_timeout=60,  # 1 minute
        retries={'max_attempts': 3}
    )
    
    # Initialize AWS clients with timeout configuration
    bedrock_runtime = boto3.client('bedrock-runtime', region_name='us-east-1', config=config)
    s3_client = boto3.client('s3', region_name='us-east-1', config=config)
    
    # Topics for fake pages
    topics = [
        "cyber-security-101",
        "http-protocol-deep-dive",
        "dns-security-fundamentals",
        "network-intrusion-detection",
        "web-application-security",
        "ssl-tls-encryption",
        "firewall-configuration",
        "penetration-testing-basics",
        "malware-analysis",
        "incident-response-procedures",
        "vulnerability-assessment",
        "secure-coding-practices",
        "authentication-mechanisms",
        "authorization-frameworks",
        "cryptography-essentials",
        "network-monitoring-tools",
        "security-information-event-management",
        "threat-intelligence",
        "digital-forensics",
        "cloud-security-architecture",
        # "zero-trust-networking",
        # "api-security-best-practices",
        # "container-security",
        # "kubernetes-security",
        # "devops-security-integration",
        # "privacy-data-protection",
        # "compliance-frameworks",
        # "risk-assessment-methodologies",
        # "security-awareness-training",
        # "business-continuity-planning"
    ]
    
    try:
        generated_pages = []
        
        # Generate 30 fake pages
        for i, topic in enumerate(topics):
            print(f"Generating page {i+1}/30: {topic}")
            
            # Create prompt for Bedrock API
            prompt = f"""Create a comprehensive HTML page about {topic.replace('-', ' ').title()}.

Requirements:
1. Use proper HTML5 structure with DOCTYPE, html, head, and body tags
2. Include CSS styling that matches a professional cybersecurity website
3. Use blue color scheme (medium saturation, low brightness)
4. Add navigation links to 3-5 other /private/ pages from this list: {', '.join([f'/private/{t}.html' for t in random.sample([t for t in topics if t != topic], 5)])}
5. Include realistic technical content with examples
6. Add a footer with fake copyright information
7. Make it look like a legitimate educational resource
8. Include meta tags for SEO
9. Add some interactive elements like code snippets or diagrams
10. Ensure the content is engaging and informative

Return only the HTML content without any additional text or explanations."""
            
            # Invoke Bedrock API directly (Claude 3 Sonnet)
            body = json.dumps({
                "anthropic_version": "bedrock-2023-05-31",
                "max_tokens": 4000,
                "messages": [
                    {
                        "role": "user",
                        "content": prompt
                    }
                ]
            })
            
            response = bedrock_runtime.invoke_model(
                modelId='anthropic.claude-3-sonnet-20240229-v1:0',
                body=body,
                contentType='application/json'
            )
            
            # Extract generated content
            response_body = json.loads(response['body'].read())
            content = response_body['content'][0]['text']
            
            # Upload to S3
            s3_key = f"private/{topic}.html"
            s3_client.put_object(
                Bucket=bucket_name,
                Key=s3_key,
                Body=content,
                ContentType='text/html',
                CacheControl='max-age=3600'
            )
            
            generated_pages.append({
                'topic': topic,
                's3_key': s3_key,
                'size': len(content)
            })
            
            print(f"Successfully generated and uploaded: {s3_key}")
        
        # Create an index page that links to all generated pages
        index_content = generate_index_page(topics)
        s3_client.put_object(
            Bucket=bucket_name,
            Key="private/index.html",
            Body=index_content,
            ContentType='text/html',
            CacheControl='max-age=3600'
        )
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': f'Successfully generated {len(generated_pages)} fake pages',
                'pages': generated_pages,
                'index_page': 'private/index.html'
            })
        }
        
    except Exception as e:
        print(f"Error: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': str(e)
            })
        }

def generate_index_page(topics):
    """Generate an index page that links to all fake pages"""
    
    links_html = ""
    for topic in topics:
        title = topic.replace('-', ' ').title()
        links_html += f'        <li><a href="/private/{topic}.html">{title}</a></li>\n'
    
    return f"""<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Private Security Resources - Bot Trapper Demo</title>
    <style>
        body {{
            font-family: Arial, sans-serif;
            background-color: #ffffff;
            color: #333;
            margin: 0;
            padding: 20px;
        }}
        .container {{
            max-width: 1200px;
            margin: 0 auto;
        }}
        h1 {{
            color: #4a6fa5;
            border-bottom: 3px solid #4a6fa5;
            padding-bottom: 10px;
        }}
        .warning {{
            background-color: #fff3cd;
            border: 1px solid #ffeaa7;
            color: #856404;
            padding: 15px;
            border-radius: 5px;
            margin: 20px 0;
        }}
        .resources-grid {{
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
            gap: 20px;
            margin-top: 30px;
        }}
        .resource-category {{
            background-color: #f8f9fa;
            border: 1px solid #dee2e6;
            border-radius: 8px;
            padding: 20px;
        }}
        .resource-category h3 {{
            color: #6f42c1;
            margin-top: 0;
        }}
        .resource-category ul {{
            list-style-type: none;
            padding: 0;
        }}
        .resource-category li {{
            margin: 8px 0;
        }}
        .resource-category a {{
            color: #4a6fa5;
            text-decoration: none;
            padding: 5px 10px;
            border-radius: 3px;
            transition: background-color 0.3s;
        }}
        .resource-category a:hover {{
            background-color: #e9ecef;
            text-decoration: underline;
        }}
        .footer {{
            margin-top: 50px;
            text-align: center;
            color: #6c757d;
            border-top: 1px solid #dee2e6;
            padding-top: 20px;
        }}
    </style>
</head>
<body>
    <div class="container">
        <h1>🔒 Private Security Resources</h1>
        
        <div class="warning">
            <strong>⚠️ Access Restricted:</strong> This directory contains sensitive security documentation and training materials. 
            Access is logged and monitored. Unauthorized access is prohibited.
        </div>
        
        <p>Welcome to our comprehensive cybersecurity resource library. These materials are designed for security professionals, 
        researchers, and students looking to deepen their understanding of information security concepts.</p>
        
        <div class="resources-grid">
            <div class="resource-category">
                <h3>📚 Available Resources</h3>
                <ul>
{links_html}
                </ul>
            </div>
        </div>
        
        <div class="footer">
            <p>&copy; 2024 Bot Trapper Demo - Cybersecurity Education Resources</p>
            <p><em>This content is generated for demonstration purposes only</em></p>
        </div>
    </div>
</body>
</html>"""
