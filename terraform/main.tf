provider "aws" {
  access_key                  = var.access_key
  secret_key                  = var.secret_key
  region                      = var.region
  skip_credentials_validation = true
  skip_requesting_account_id  = true
  skip_metadata_api_check     = true
  s3_use_path_style           = true

  endpoints {
    lambda = var.lambda_endpoint
    s3     = var.s3_endpoint
    sqs    = var.sqs_endpoint
  }
}

resource "aws_s3_bucket" "sqlai_bucket" {
  bucket = "lambda-functions"
}

resource "aws_sqs_queue" "training_task_queue" {
  name = "training-task-queue"
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.training_task_dead_letter_queue.arn
    maxReceiveCount     = 3
  })
}

resource "aws_sqs_queue" "training_task_dead_letter_queue" {
  name = "training-task-dead-letter-queue"
}

resource "aws_lambda_function" "write_training_data_to_db" {
  function_name    = "write-training-data-to-db"
  runtime          = "python3.10"
  handler          = "write_training_data_to_db.lambda_handler"
  role             = "arn:aws:iam::000000000000:role/lambda"
  filename         = "../src/lambda/write_training_data_to_db.zip"
  source_code_hash = filebase64sha256("../src/lambda/write_training_data_to_db.zip")

  environment {
    variables = {
      TRAINING_QUEUE_URL = aws_sqs_queue.training_task_queue.id
      TRAINING_DLQ_URL = aws_sqs_queue.training_task_dead_letter_queue.id
    }
  }

  dead_letter_config {
    target_arn = aws_sqs_queue.training_task_dead_letter_queue.arn
  }
}

resource "aws_lambda_event_source_mapping" "training_event_source_mapping" {
  event_source_arn = aws_sqs_queue.training_task_queue.arn
  function_name    = aws_lambda_function.write_training_data_to_db.arn
}
