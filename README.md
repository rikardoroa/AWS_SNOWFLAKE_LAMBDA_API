
# AWS Snowflake Pipeline for Fire Incidents Data Capture

## Project Description

### 1. Project Features

This project uses several AWS Services and Snowflake as Datawarehouse to capture incremental data from https://data.sfgov.org/Public-Safety/Fire-Incidents/wr8u-xric/about_data,
the final output is a materialized view from a permanent table, that will be the primary object to create the several necessary dimensions.

## AWS CLI Installation and Bucket Configuration for Terraform

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

4. **Terraform Environment Configuration**:
   
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

## Bucket Configuration for AWS Lambda and AWS Glue Resources

### 1. Bucket Creation for Lambda and Glue

The `lambda_module` in the Terraform environment contains a `buckets.json` file. Ensure each bucket name is unique to avoid errors:

```json
{
  "buckets": [
      { "name": "dev-fire-incidents-dt" }, 
      { "name": "dev-fire-incidents-dt-all" },
      { "name": "dev-fire-incidents-dt-glue-python" }
  ]
}
```
- The bucket **__dev-fire-incidents-dt__** ingest the API Calls executed by the AWS Lambda Function, the files in this bucket, will be deleted after the glue job is executed, this will prevent keep unnesseray files in the bucket

- The bucket **__dev-fire-incidents-dt-all__** store the incremental load executed by AWS Glue Job

- The bucket **__dev-fire-incidents-dt-glue-python__** will store the AWS Glue Job code

- The bucket **__dev-fire-incidents-dt__** is env variable for the AWS Lambda Function and that value is configured in **__variables.tf__** file from the **__lambda_module__** as follows:

   ```hcl
        variable "lambda_bucket"{
            description = "Bucket to store the API Call data execute by the AWS Lambda Function"
            type = string
            default = "dev-fire-incidents-dt"

        }

    ```
- For Changing the Bucket names follow the previous validation and also follow the configuration steps described below.


### 2. Changing Bucket Names

To modify bucket names, update the `outputs.tf` file in the `lambda_module` and the `buckets.json` file :

```hcl
output "glue_bucket" {
    value = aws_s3_bucket.bucket_creation["dev-fire-incidents-dt-glue-python"].id
}
```

Replace the bucket name as necessary:

```hcl
output "glue_bucket" {
    value = aws_s3_bucket.bucket_creation["my_other_bucket"].id
}
```

### 3. Configuring AWS Regions for Resources

The Glue and Lambda modules contain a `providers.tf` file for region configuration. Ensure your AWS region is set correctly:

```hcl
provider "aws" {
    region = "us-east-2"
}
```

Update the region in the `variables.tf` file as well:

```hcl
variable "aws_region" {
    description = "aws region"
    type = string
    default = "us-east-2"
}
```

## Backend Configuration for Terraform State

To capture changes in your Terraform configuration, update the `backend.hcl` file with the correct bucket name, if you want to change, verify and check if the bucket is available, apply the previous steps , this is entry in the mentioned `backend.hcl` file:

```hcl
bucket = "dev-fire-incidents-dt-tf-state"
```

## Project Description

### Project Structure for AWS_PIPELINE_SNOWFLAKE Repository:

```bash
.
├── .github/
│   └── workflows/
│       ├── AWS_CREATION_PIPELINE_SN.yml
│       ├── AWS_DESTROY_PIPELINE_SN.yml
│       └── SNOWFLAKE_RESOURCES.yml
├── aws_pipeline_deployment/
│   ├── glue_module/
│   │   ├── glue_script/
│   │   │   └── GlueJobScript.py
│   │   ├── glue.tf
│   │   ├── providers.tf
│   │   └── variables.tf
│   ├── lambda_module/
│   │   ├── resources/
│   │   │   ├── python/
│   │   │   │   └── aws_lambda/
│   │   │   │       ├── api_calls.py
│   │   │   │       └── lambda_function.py
│   │   │   ├── Dockerfile
│   │   │   └── requirements.txt
│   │   ├── bucket.tf
│   │   ├── buckets.json
│   │   ├── docker.tf
│   │   ├── iam_role.tf
│   │   ├── lambda.tf
│   │   ├── local.tf
│   │   ├── outputs.tf
│   │   ├── providers.tf
│   │   └── variables.tf
├── main.tf
├── versions.tf
├── resource_queries/
│   ├── V0.1.1_file_format.sql
│   ├── V0.1.2_external_table.sql
│   ├── V0.1.3_stream_creation.sql
│   ├── V0.1.4_permanent_table_creation.sql
│   ├── V0.1.5_materialized_view.sql
│   └── V0.1.6_task_creation.sql
├── backend.hcl
└── README.md
```

### Key Directories:

1. **workflows**: CI/CD files to create AWS and Snowflake resources.

2. **glue_module**: Contains Python and Terraform files to deploy the Glue job, capturing incremental updates from the Fire Incidents API.

3. **lambda_module**: Contains Python, Docker, and Terraform configuration files to deploy AWS Lambda and S3 buckets for API data storage with KMS encryption.

4. **aws_pipeline_deployment**: The root directory containing Glue and Lambda modules. It also includes **main.tf** and **versions.tf** for detecting changes when workflows are deployed via GitHub Actions.

5. **resource_queries**: SQL queries to create Snowflake resources for data ingestion.

## Before Workflows Execution

1. Before execute the Github Actions Workflows is necessary acomplish some prerequisites:
   - Is necessery create your Snowflake Database, Schema and Warehouse

   - Create Storage Integration and Configure a Role in your AWS Console for secure access, to do so you can follow this Snowflake documentation here: https://docs.snowflake.com/en/user-guide/data-load-s3-config-storage-integration or follow this youtube video: https://www.youtube.com/watch?v=eCQTKpcOaMg

   - Create and Configure a Snowflake Stage, attach the bucket in the stage configuration, like follows:
     
     ```sql
        
            CREATE OR REPLACE STAGE your_stage
            URL='s3://your_bucket/path/'
            DIRECTORY = ( ENABLE = TRUE,  AUTO_REFRESH = true )
            STORAGE_INTEGRATION = your_storage_integration;
     ```

     After that do **__DESC STAGE your_stage__** and copy the SQS ARN value and create a notificacion event in the S3 Bucket Configured in the AWS Lambda Function, this step is important because the SQS will capture the new data ingested in the S3 Bucket to capture the incremental data in Snowflake, you can follow this Snowflake official documentation: https://docs.snowflake.com/en/user-guide/data-load-dirtables-auto-s3#option-1-creating-a-new-s3-event-notification


    - Set up your Snowflake Credentials in Github as Secrets for **__ROLE__**, **__ACCOUNT__**,**__SCHEMA__**,**__DATABASE__**,**__WAREHOUSE__**,**__PASSWORD__** and **__USER__**


    - Set up a value for **__SCHEMACHANGE_VAR__** in Github as a secret to store **__SCHEMA__**,**__DATABASE__**,**__WAREHOUSE__**, **__ROLE__** and **__BUCKET__**, for example:
    ```json
            {
                "database":"your_database",
                "schema":"your_schema",
                "role":"arn:aws:iam::your_account_id:role/your_role_name",
                "bucket":"your_bucket",
                "warehouse":"your_warehouse"
            }
    ```
    - Create the CHANGE_HISTORY table in Snowflake with in your current Datababase and Warehouse that you are using for the project

    - Set up the Dates for Both Event Bridge Schedulers related to AWS Glue Job and AWS Lambda Function, those Dates entries are located in **__glue.tf__** and **__lambda.tf files__**
           

## Workflows Execution

1. The project will Run **__AWS_CREATION_PIPELINE_SN__**  Workflow on **__push__**, to run successfully this Worflow everything needs to be set up.

2. After Run **__AWS_CREATION_PIPELINE_SN__** , the Workflow **__SNOWFLAKE_RESOURCES__** can be executed Manually, because is using **__Workflow__dispatch__** action, thiw workflow will create every Snowflake Object to capture de data incrementally from the Stage, the incrementall capture will Fail if the Snowflake enviroment is not configured correctly.

3. The Worflow **__AWS_DESTROY_PIPELINE_SN__** is optional, and also is configured to be executed Manually By the user, this Workflow will do a deletion of every Resource Created by terraform, after deletion is necessary to Set up Again the AWS Lambda Bucket with an Event Notification using the SQS Generated by Snowflake.

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

### 2. Schemachange Table Creation

Before using GitHub Actions to deploy objects via Schemachange, create the following Snowflake table to track changes:

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

### 3. Snowflake Credentials

To successfully deploy Snowflake objects via GitHub Actions, ensure full authentication using the following credentials:

- **ACCOUNT**
- **USER**
- **ROLE**
- **PASSWORD**
- **WAREHOUSE**
- **DATABASE**
