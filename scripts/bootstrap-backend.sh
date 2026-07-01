# scripts/bootstrap-backend.sh
#!/bin/bash
set -e

AWS_REGION="us-east-1"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
BUCKET_NAME="terraform-state-ha-project-${ACCOUNT_ID}"
TABLE_NAME="terraform-state-locks"

echo "Creating S3 backend bucket: ${BUCKET_NAME}"

# Create the S3 bucket
aws s3api create-bucket \
  --bucket "${BUCKET_NAME}" \
  --region "${AWS_REGION}"

# Enable versioning (so you can recover from bad applies)
aws s3api put-bucket-versioning \
  --bucket "${BUCKET_NAME}" \
  --versioning-configuration Status=Enabled

# Enable server-side encryption
aws s3api put-bucket-encryption \
  --bucket "${BUCKET_NAME}" \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }]
  }'

# Block all public access
aws s3api put-public-access-block \
  --bucket "${BUCKET_NAME}" \
  --public-access-block-configuration \
    'BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true'

echo "Creating DynamoDB lock table: ${TABLE_NAME}"

# Create the DynamoDB lock table
aws dynamodb create-table \
  --table-name "${TABLE_NAME}" \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region "${AWS_REGION}"

echo ""
echo "Backend bootstrap complete!"
echo "Bucket: ${BUCKET_NAME}"
echo "Table:  ${TABLE_NAME}"
echo ""
echo "Add this to your versions.tf backend block:"
echo "  bucket = \"${BUCKET_NAME}\""
