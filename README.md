
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
   
   - **Check if the Bucket Exists**:
        ```bash
        aws s3api head-bucket --bucket your_bucket
        ```
        If you receive the error `An error occurred (404) when calling the HeadBucket operation: Not Found`, the bucket does not exist and can be created.

   - **Create DynamoDB Table for Terraform State Locking**:
        ```bash
        aws dynamodb create-table --table-name terraform-lock-table --attribute-definitions AttributeName=LockID,AttributeType=S --key-schema AttributeName=LockID,KeyType=HASH --billing-mode PAY_PER_REQUEST --region your_region
        ```
        Replace `your_region` with the actual AWS region (e.g., `us-east-2`).

   - **Create S3 Bucket for Terraform State**:
        ```bash
        aws s3api create-bucket --bucket your_bucket --region your_region --create-bucket-configuration LocationConstraint=your_region
        ```
        Replace `your_bucket` with a unique bucket name.

   - **Apply Bucket Policies**:
        ```bash
        aws s3api put-public-access-block --bucket your_bucket --public-access-block-configuration BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true
        ```

### 4. Backend Configuration for Terraform State

To capture changes in your Terraform configuration, update the `backend.hcl` file with the correct bucket name, if you want to change, verify and check if the bucket is available, apply the previous steps , this is entry in the mentioned `backend.hcl` file:

```hcl
bucket = "dev-fire-incidents-dt-tf-state"
```


### 5. Create a snowflake trail account 

Before using this project is necessary set up a snowflake trial account , this tutorial is hepful: https://anishmahapatra.medium.com/how-to-set-up-a-free-snowflake-account-0cb7d00b230a


### 6. Set up important configuration after account creation

After the account creation is necessary to configure several things as follow:

1. **Create a STORAGE INTEGRATION**:

- **role creation**: to set up a storage integration is necessary to create a AWS IAM ROLE with **__AmazonS3FullAccess__** permissions this is for this practice only

- **bucket creation**: after the role definition is necessary also the creation of a S3 bucket, verify if the bucket exist in AWS before create it, also the bucket must be defines in terraform environment variables regarding the  **__lambda module__**, this is how the bucket is defined in **__bucket.tf__** file like this:
```hcl
    variable "curated_bucket" {
        description = "curated bucket"
        type = string
        default = "api-snowflake-data"
    }
```
- **load csv files in aws S3**: after the bucket creation is necessary load the csv files for this project in AWS S3 you can use  aws cli console or AWS GUI, the files are located in the root folder of the project


- **storage integration creation**: after set up the role is necessary create the **__STORAGE INTEGRATION FEATURE__** as follows:
```sql
      CREATE OR REPLACE STORAGE INTEGRATION api_data_aws_integration
        TYPE = EXTERNAL_STAGE
        STORAGE_PROVIDER = 'S3'
        STORAGE_AWS_ROLE_ARN =  'arn role' 
        ENABLED = TRUE
        STORAGE_ALLOWED_LOCATIONS = ('your bucket url');
```

- **trust relationship**: after the role and storage integration are created is necessary to establish a **__trust relationship__** to permit the AWS S3 bucket connection with the snowflake stage to query the data, this snowflake tutorial is very complete related to the steps to do all the configuration for the AWS side :https://docs.snowflake.com/en/user-guide/data-load-s3-config-storage-integration, this is also a youtube tutorial https://www.youtube.com/watch?v=eCQTKpcOaMg&t=847s



- **database and schema creation**: after set up all the previous steps is necessary to create the database and schema manually as follows:

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

- **SNOWFLAKE_ACCOUNT as ACCOUNT**
- **SNOWFLAKE_USER as USER**
- **SNOWFLAKE_ROLE as ROLE**
- **SNOWFLAKE_PASSWORD as PASSWORD**
- **SNOWFLAKE_WH  as WAREHOUSE**
- **SNOWFLAKE_DB as DATABASE**
- **SNOWFLAKE_SCHEMA as SCHEMA**
- **AWS_ACCESS_KEY_ID**
- **AWS_SECRET_ACCESS_KEY**
also is necessary define the variable **__SCHEMACHANGE_VAR__** as  a secret in our repository follows:
```json
'{"database": "my_database_valu", "schema": "my_schema_value"}'
```


## Project Structure

### 1. Project Structure for AWS_PIPELINE_SNOWFLAKE Repository:

```bash
    ├── .github/
    │   └── workflows/
    │       ├── AWS_CREATION_PIPELINE_SN.yml
    │       ├── AWS_DESTROY_PIPELINE_SN.yml
    │       └── SNOWFLAKE_RESOURCES.yml
    ├── aws_pipeline_deployment/
    │   ├── api_gateway_module/
    │   │   ├── api_getaway.tf
    │   │   ├── providers.tf
    │   │   └── variables.tf
    │   ├── lambda_module/
    │   │   ├── bucket.tf
    │   │   ├── docker.tf
    │   │   ├── iam_role.tf
    │   │   ├── lambda.tf
    │   │   ├── outputs.tf
    │   │   ├── providers.tf
    │   │   ├── variables.tf
    │   │   └── resources/
    │   │       ├── Dockerfile
    │   │       ├── requirements.txt
    │   │       └── python/
    │   │           └── aws_lambda/
    │   │               ├── get.py
    │   │               ├── lambda_function.py
    │   │               ├── post.py
    │   │               └── snowflake_response.py
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

### 2. Key Directories:

1. **workflows**: CI/CD files to create AWS and Snowflake resources.

2. **api_gateway_module**: Contains  Terraform files to deploy the API Gateway for get and post methods

3. **lambda_module**: Contains Python, Docker, and Terraform configuration files to deploy AWS Lambda and S3 buckets for API data storage with KMS encryption.

4. **aws_snowflake_lambda_api**: The root directory containing Api Gateway and Lambda modules. It also includes **main.tf** and **versions.tf** for detecting changes when workflows are deployed via GitHub Actions.

5. **resource_queries**: SQL queries to create Snowflake resources for data ingestion.


### 3. Workflows Execution

1. The project will Run **__AWS_CREATION_PIPELINE_SN__**  Workflow on **__push__**, to run successfully this Worflow everything needs to be set up.

2. After Run **__AWS_CREATION_PIPELINE_SN__** , the Workflow **__SNOWFLAKE_RESOURCES__** can be executed Manually, because is using **__Workflow__dispatch__** action, thiw workflow will create every Snowflake Object to capture de data incrementally from the Stage, the incrementall capture will Fail if the Snowflake enviroment is not configured correctly.

3. The Worflow **__AWS_DESTROY_PIPELINE_SN__** is optional, and also is configured to be executed Manually By the user, this Workflow will do a deletion of every Resource Created by terraform.

## Snowflake Schemachange

### 1. Schemachange Considerations

The Schemachange tool expects a folder structure similar to the following:

```bash
(project_root)
├── folder_1
│   ├── V1.1.1__first_change.sql
│   ├── V1.1.2__second_change.sql
│   ├── R__sp_add_sales.sql
│   └── R__fn_get_timezone.sql
├── folder_2
│   └── folder_3
│       ├── V1.1.3__third_change.sql
│       └── R__fn_sort_ascii.sql
```

Each version annotation is linked to a Snowflake object (table, file format, stream, etc.) and must follow versioning best practices:

- **Prefix**: 'V' for versioned changes.
- **Version**: A unique version number.
- **Separator**: Two underscores (`__`).
- **Description**: An arbitrary description with words separated by underscores or spaces (cannot include two underscores).
- **Suffix**: `.sql` or `.sql.jinja`.

