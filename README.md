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

  If you receive the error `An error occurred (404) when calling the HeadBucket operation: Not Found`, the bucket does not exist and can be created.

* **Create DynamoDB Table for Terraform State Locking**:

  ```bash
  aws dynamodb create-table --table-name terraform-lock-table --attribute-definitions AttributeName=LockID,AttributeType=S --key-schema AttributeName=LockID,KeyType=HASH --billing-mode PAY_PER_REQUEST --region your_region
  ```

  Replace `your_region` with the actual AWS region (e.g., `us-east-2`).

* **Create S3 Bucket for Terraform State**:

  ```bash
  aws s3api create-bucket --bucket your_bucket --region your_region --create-bucket-configuration LocationConstraint=your_region
  ```

  Replace `your_bucket` with a unique bucket name.

* **Apply Bucket Policies**:

  ```bash
  aws s3api put-public-access-block --bucket your_bucket --public-access-block-configuration BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true
  ```

### 4. Backend Configuration for Terraform State

To capture changes in your Terraform configuration, update the `backend.hcl` file with the correct bucket name, if you want to change, verify and check if the bucket is available, apply the previous steps , this is entry in the mentioned `backend.hcl` file:

```hcl
bucket = "dev-fire-incidents-dt-tf-state"
```

### 5. Create a snowflake trail account

Before using this project is necessary set up a snowflake trial account , this tutorial is hepful: [https://anishmahapatra.medium.com/how-to-set-up-a-free-snowflake-account-0cb7d00b230a](https://anishmahapatra.medium.com/how-to-set-up-a-free-snowflake-account-0cb7d00b230a)

### 6. Set up important configuration after account creation

After the account creation is necessary to configure several things as follow:

1. **Create a STORAGE INTEGRATION**:

* **role creation**: to set up a storage integration is necessary to create a AWS IAM ROLE with ****AmazonS3FullAccess**** permissions this is for this practice only

* **bucket creation**: after the role definition is necessary also the creation of a S3 bucket, verify if the bucket exist in AWS before create it, also the bucket must be defines in terraform environment variables regarding the  ****lambda module****, this is how the bucket is defined in ****bucket.tf**** file like this:

```hcl
    variable "curated_bucket" {
        description = "curated bucket"
        type = string
        default = "api-snowflake-data"
    }
```

* **load csv files in aws S3**: after the bucket creation is necessary load the csv files for this project in AWS S3 you can use  aws cli console or AWS GUI, the files are located in the root folder of the project

* **storage integration creation**: after set up the role is necessary create the ****STORAGE INTEGRATION FEATURE**** as follows:

```sql
      CREATE OR REPLACE STORAGE INTEGRATION api_data_aws_integration
        TYPE = EXTERNAL_STAGE
        STORAGE_PROVIDER = 'S3'
        STORAGE_AWS_ROLE_ARN =  'arn role' 
        ENABLED = TRUE
        STORAGE_ALLOWED_LOCATIONS = ('your bucket url');
```

* **trust relationship**: after the role and storage integration are created is necessary to establish a ****trust relationship**** to permit the AWS S3 bucket connection with the snowflake stage to query the data, this snowflake tutorial is very complete related to the steps to do all the configuration for the AWS side :[https://docs.snowflake.com/en/user-guide/data-load-s3-config-storage-integration](https://docs.snowflake.com/en/user-guide/data-load-s3-config-storage-integration), this is also a youtube tutorial [https://www.youtube.com/watch?v=eCQTKpcOaMg\&t=847s](https://www.youtube.com/watch?v=eCQTKpcOaMg&t=847s)

* **database and schema creation**: after set up all the previous steps is necessary to create the database and schema manually as follows:

```sql
    CREATE DATABASE IF NOT EXISTS API_LAYER;

    CREATE SCHEMA IF NOT EXISTS API_DATA;
```

### 7. Schemachange Table Creation

I am using Schemachange to create and deploy snowflake objects into snowflake environment, so before using GitHub Actions to deploy objects via Schemachange, create the following Snowflake table in the schema mentioned below otherwise the deployment will fail, this table is to track object changes after deployment :

```sql
CREATE TABLE IF NOT EXISTS CHANGE_HISTORY
(
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

### 8. Snowflake Credentials and AWS Credentials

To successfully deploy Snowflake and AWS objects via GitHub Actions, ensure full authentication using the following credentials:

* **SNOWFLAKE\_ACCOUNT as ACCOUNT**
* **SNOWFLAKE\_USER as USER**
* **SNOWFLAKE\_ROLE as ROLE**
* **SNOWFLAKE\_PASSWORD as PASSWORD**
* **SNOWFLAKE\_WH  as WAREHOUSE**
* **SNOWFLAKE\_DB as DATABASE**
* **SNOWFLAKE\_SCHEMA as SCHEMA**
* **AWS\_ACCESS\_KEY\_ID**
* **AWS\_SECRET\_ACCESS\_KEY**
  also is necessary define the variable ****SCHEMACHANGE\_VAR**** as  a secret in our repository follows:

```bash
    '{"database": "my_database_value", "schema": "my_schema_value"}'
```

## API Usage

### 1. POST method

**Endpoint:**

```
POST https://2kqz8zbti2.execute-api.us-east-2.amazonaws.com/dev/SnowflakeGetData?table=jobs
```

**Body (JSON):**

```json
[
  {"JOB_NAME": "IT Support"},
  {"JOB_NAME": "Data Scientist"},
  {"JOB_NAME": "AI Researcher"},
  {"JOB_NAME": "Backend Developer"},
  {"JOB_NAME": "Backend Developer"},
  {"JOB_NAME": "DevOps Engineer"},
  {"JOB_NAME": "Backend Developer"},
  {"JOB_NAME": "IT Support"},
  {"JOB_NAME": "System Analyst"}
]
```

### 2. GET method

**Endpoint:**

```
GET https://2kqz8zbti2.execute-api.us-east-2.amazonaws.com/dev/SnowflakeGetData?table=jobs
```

**Description:**
Returns the content of the `jobs` table from Snowflake.

### 3. POST example for departments

**Endpoint:**

```
POST https://2kqz8zbti2.execute-api.us-east-2.amazonaws.com/dev/SnowflakeGetData?table=departments
```

**Body (JSON):**

```json
[
  {"DEPARTMENT_NAME": "Staff"},
  {"DEPARTMENT_NAME": "Supply Chain"},
  {"DEPARTMENT_NAME": "Technology"}
]
```

### 4. POST example for employees

**Endpoint:**

```
POST https://2kqz8zbti2.execute-api.us-east-2.amazonaws.com/dev/SnowflakeGetData?table=employee
```

**Body (JSON):**

```json
[
  {
    "EMPLOYEE_NAME": "Ricardo Roa",
    "EMPLOYEE_HIRED_DATE": "2021-03-22",
    "EMPLOYEE_DPT_ID": 1,
    "EMPLOYEE_JOB_ID": 1
  },
  {
    "EMPLOYEE_NAME": "Ana López",
    "EMPLOYEE_HIRED_DATE": "2021-06-15",
    "EMPLOYEE_DPT_ID": 2,
    "EMPLOYEE_JOB_ID": 2
  }
]
```
