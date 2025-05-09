# AWS Snowflake Pipeline for API Integration and Development with AWS Services

## General overview for configuration

### 1. Project Features

This project use two AWS Services to ingest data into snowflake using AWS API Gateway and one single AWS Lambda instance

## Prerequisites

### 1. AWS CLI Installation

The AWS CLI is essential for managing credentials and configuring the environment. Follow the steps below for installation:

1. **Install AWS CLI**:

   ```bash
   brew install awscli
   ```

2. **Verify Installation**:

   ```bash
   aws --version
   ```

3. **Windows Installation**:
   For Windows users, refer to the [AWS CLI Installation Guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html).

### 2. Terraform Environment Configuration:

* **Check if the Bucket Exists**:

  ```bash
  aws s3api head-bucket --bucket your_bucket
  ```

* **Create DynamoDB Table for Terraform State Locking**:

  ```bash
  aws dynamodb create-table --table-name terraform-lock-table \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST --region your_region
  ```

* **Create S3 Bucket for Terraform State**:

  ```bash
  aws s3api create-bucket --bucket your_bucket --region your_region \
    --create-bucket-configuration LocationConstraint=your_region
  ```

* **Apply Bucket Policies**:

  ```bash
  aws s3api put-public-access-block --bucket your_bucket \
    --public-access-block-configuration BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true
  ```

### 3. Backend Configuration for Terraform State

Update the `backend.hcl` file:

```hcl
bucket = "dev-fire-incidents-dt-tf-state"
```

### 4. Snowflake Trial Account

Set up a trial account: [Tutorial](https://anishmahapatra.medium.com/how-to-set-up-a-free-snowflake-account-0cb7d00b230a)

### 5. Storage Integration Configuration

* Create IAM role with `AmazonS3FullAccess`
* Create S3 bucket (ensure it's defined in `bucket.tf`):

```hcl
variable "curated_bucket" {
  description = "curated bucket"
  type        = string
  default     = "api-snowflake-data"
}
```

* Upload CSVs to S3
* Create storage integration in Snowflake:

```sql
CREATE OR REPLACE STORAGE INTEGRATION api_data_aws_integration
  TYPE = EXTERNAL_STAGE
  STORAGE_PROVIDER = 'S3'
  STORAGE_AWS_ROLE_ARN = 'arn role'
  ENABLED = TRUE
  STORAGE_ALLOWED_LOCATIONS = ('your bucket url');
```

* Set trust relationship (see [Snowflake docs](https://docs.snowflake.com/en/user-guide/data-load-s3-config-storage-integration) and [YouTube tutorial](https://www.youtube.com/watch?v=eCQTKpcOaMg&t=847s))
* Create database and schema:

```sql
CREATE DATABASE IF NOT EXISTS API_LAYER;
CREATE SCHEMA IF NOT EXISTS API_DATA;
```

### 6. Schemachange Setup

I am using Schemachange to create and deploy Snowflake objects into the Snowflake environment, so before using GitHub Actions to deploy objects via Schemachange, create the following Snowflake table in the schema mentioned below. Otherwise, the deployment will fail. This table is used to track object changes after deployment:

* Required table:

```sql
CREATE TABLE IF NOT EXISTS CHANGE_HISTORY (
  VERSION VARCHAR,
  DESCRIPTION VARCHAR,
  SCRIPT VARCHAR,
  SCRIPT_TYPE VARCHAR,
  CHECKSUM VARCHAR,
  EXECUTION_TIME NUMBER,
  STATUS VARCHAR,
  INSTALLED_BY VARCHAR,
  INSTALLED_ON TIMESTAMP_LTZ
);
```

* Scripts must follow naming like:

```
V0.1.5__hiring_avg_2021_view.sql
```

* Define in GitHub Secrets:

```bash
SCHEMACHANGE_VAR='{"database": "API_LAYER", "schema": "API_DATA"}'
```

### 7. AWS/Snowflake Credentials (for GitHub Actions)

Set these in your repo secrets:

* SNOWFLAKE\_ACCOUNT, SNOWFLAKE\_USER, SNOWFLAKE\_ROLE, SNOWFLAKE\_PASSWORD
* SNOWFLAKE\_WH, SNOWFLAKE\_DB, SNOWFLAKE\_SCHEMA
* AWS\_ACCESS\_KEY\_ID, AWS\_SECRET\_ACCESS\_KEY
* SCHEMACHANGE\_VAR

## Project Structure

### 2. Key Directories:

1. **workflows**: CI/CD files to create AWS and Snowflake resources.

2. **api\_gateway\_module**: Contains Terraform files to deploy the API Gateway for GET and POST methods.

3. **lambda\_module**: Contains Python, Docker, and Terraform configuration files to deploy AWS Lambda and S3 buckets for API data storage with KMS encryption.

4. **aws\_snowflake\_lambda\_api**: The root directory containing API Gateway and Lambda modules. It also includes **main.tf** and **versions.tf** for detecting changes when workflows are deployed via GitHub Actions.

5. **resource\_queries**: SQL queries to create Snowflake resources for data ingestion.

### 3. Workflows Execution

| Workflow Name               | Trigger Type      | Description                                                             |
| --------------------------- | ----------------- | ----------------------------------------------------------------------- |
| AWS\_CREATION\_PIPELINE\_SN | push              | Deploys all AWS infrastructure (Lambda, API Gateway, S3, IAM, etc.)     |
| SNOWFLAKE\_RESOURCES        | manual (dispatch) | Deploys Snowflake objects (tables, stages, streams, etc.)               |
| AWS\_DESTROY\_PIPELINE\_SN  | manual (dispatch) | Destroys all resources created by Terraform (used for clean-up/testing) |

```bash
├── .github/workflows/
│   ├── AWS_CREATION_PIPELINE_SN.yml
│   ├── AWS_DESTROY_PIPELINE_SN.yml
│   └── SNOWFLAKE_RESOURCES.yml
├── aws_pipeline_deployment/
│   ├── api_gateway_module/
│   │   ├── api_getaway.tf
│   │   ├── providers.tf
│   │   └── variables.tf
│   └── lambda_module/
│       ├── bucket.tf
│       ├── docker.tf
│       ├── iam_role.tf
│       ├── lambda.tf
│       ├── outputs.tf
│       ├── providers.tf
│       ├── variables.tf
│       └── resources/
│           ├── Dockerfile
│           ├── requirements.txt
│           └── python/aws_lambda/
│               ├── get.py
│               ├── lambda_function.py
│               ├── post.py
│               └── snowflake_response.py
├── resource_queries/
│   ├── V0.1.1__file_format.sql
│   ├── V0.1.2__stage_creation.sql
│   ├── V0.1.3__tables_creation.sql
│   ├── V0.1.4__employee_view.sql
│   └── V0.1.5__hiring_avg_2021_view.sql
├── backend.hcl
├── main.tf
├── versions.tf
└── README.md
```

## API Usage

### POST example - jobs

**Endpoint:**

```
POST https://dummyapigateway.execute-api.us-east-2.amazonaws.com/dev/SnowflakeGetData?table=jobs
```

**Body:**

```json
[
  {"JOB_NAME": "IT Support"},
  {"JOB_NAME": "Data Scientist"},
  {"JOB_NAME": "AI Researcher"},
  {"JOB_NAME": "Backend Developer"},
  {"JOB_NAME": "DevOps Engineer"}
]
```

### GET example - jobs

**Endpoint:**

```
GET https://dummyapigateway.execute-api.us-east-2.amazonaws.com/dev/SnowflakeGetData?table=jobs
```

**Body:**

```json
[
   {
        "JOB_ID": 1,
        "JOB_NAME": "Backend Developer"
    },
    {
        "JOB_ID": 2,
        "JOB_NAME": "DevOps Engineer"
    }
]
```

### POST example - departments

**Endpoint:**

```
POST https://dummyapigateway.execute-api.us-east-2.amazonaws.com/dev/SnowflakeGetData?table=departments
```

**Body:**

```json
[
  {"DEPARTMENT_NAME": "Technology"},
  {"DEPARTMENT_NAME": "Finance"},
  {"DEPARTMENT_NAME": "Human Resources"}
]
```

### GET example - departments

**Endpoint:**

```
GET https://dummyapigateway.execute-api.us-east-2.amazonaws.com/dev/SnowflakeGetData?table=departments
```

**Body:**

```json
[
   {
        "DEPARTMENT_ID": 1,
        "DEPARTMENT_NAME": "IT Support 2999"
    },
    {
        "DEPARTMENT_ID": 2,
        "DEPARTMENT_NAME": "QA 3000"
    }
]
```


### POST example - employee

**Endpoint:**

```
POST https://dummyapigateway.execute-api.us-east-2.amazonaws.com/dev/SnowflakeGetData?table=employee
```

**Body:**

```json
[
  {
    "EMPLOYEE_NAME": "Alice Smith",
    "EMPLOYEE_HIRED_DATE": "2021-07-01",
    "EMPLOYEE_DPT_ID": 2,
    "EMPLOYEE_JOB_ID": 5
  },
  {
    "EMPLOYEE_NAME": "John Doe",
    "EMPLOYEE_HIRED_DATE": "2021-05-01",
    "EMPLOYEE_DPT_ID": 7,
    "EMPLOYEE_JOB_ID": 3
  }
]
```

### GET example - employee

**Endpoint:**

```
GET https://dummyapigateway.execute-api.us-east-2.amazonaws.com/dev/SnowflakeGetData?table=employee
```

**Body:**

```json
[
   {
        "EMPLOYEE_ID": 1,
        "EMPLOYEE_NAME": "Alice Smith",
        "EMPLOYEE_HIRED_DATE": "2021-01-01",
        "EMPLOYEE_DPT_ID": 2,
        "EMPLOYEE_JOB_ID": 5
    },
    {
        "EMPLOYEE_ID": 2,
        "EMPLOYEE_NAME": "John Doe",
        "EMPLOYEE_HIRED_DATE": "2021-05-01",
        "EMPLOYEE_DPT_ID": 7,
        "EMPLOYEE_JOB_ID": 3
    }
]
```