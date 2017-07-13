# Variables
variable "region" {
  default = "eu-west-1"
}
variable "account_id" {}
variable "s3_bucket" {}
variable "lambda_name" {
  default = "plambdapi"
}

provider "aws" {
  region = "${var.region}"
}

# S3 Bucket
resource "aws_s3_bucket" "bucket" {
  bucket = "${var.s3_bucket}"
  acl = "public-read"
}

# API Gateway
resource "aws_api_gateway_rest_api" "api" {
  name = "${var.lambda_name}_api"
}

resource "aws_api_gateway_resource" "api_resource" {
  rest_api_id = "${aws_api_gateway_rest_api.api.id}"
  parent_id   = "${aws_api_gateway_rest_api.api.root_resource_id}"
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "method" {
  rest_api_id   = "${aws_api_gateway_rest_api.api.id}"
  resource_id   = "${aws_api_gateway_resource.api_resource.id}"
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "integration" {
  rest_api_id             = "${aws_api_gateway_rest_api.api.id}"
  resource_id             = "${aws_api_gateway_resource.api_resource.id}"
  http_method             = "${aws_api_gateway_method.method.http_method}"
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/${aws_lambda_function.lambda.arn}/invocations"
}

# Lambda
resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.lambda.arn}"
  principal     = "apigateway.amazonaws.com"

  # More: http://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-control-access-using-iam-policies-to-invoke-api.html
  source_arn = "arn:aws:execute-api:${var.region}:${var.account_id}:${aws_api_gateway_rest_api.api.id}/*/${aws_api_gateway_method.method.http_method}/{proxy+}"
}

resource "aws_lambda_function" "lambda" {
  filename         = "lambda.zip"
  function_name    = "${var.lambda_name}"
  role             = "arn:aws:iam::032826422072:role/lambda_basic_execution"
  handler          = "lambda.handler"
  runtime          = "python3.6"
  source_code_hash = "${base64sha256(file("lambda.zip"))}"

  environment {
    variables = {
      S3_BUCKET = "${var.s3_bucket}"
    }
  }
}



