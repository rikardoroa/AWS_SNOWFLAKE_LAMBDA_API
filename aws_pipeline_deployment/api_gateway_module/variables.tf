variable  "invoke_arn" {
  type  = string
}

variable "function_name" {
  type = string
}


variable "region"{
  description = "aws region"
  type = string
  default = "us-east-2"

}