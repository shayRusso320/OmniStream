###############################################################################
# Terraform – AWS DynamoDB Table (Free Tier)
#
# Schema:
#   Primary key : PK (hash) + SK (range)
#   GSI         : GSI-SK-PK  →  SK (hash) + PK (range)
#
# Billing:
#   PROVISIONED mode is required for AWS Free Tier.
#   Free tier includes 25 RCU + 25 WCU per month shared across all tables.
#   Defaults are set to 5 RCU / 5 WCU per table — well within the free tier
#   for a low-throughput project.
#
# Stream:
#   Fires on every write (INSERT / MODIFY / REMOVE).
#   Event-source mapping filter ensures only records where
#   dynamodb.NewImage.need_summary.BOOL == true reach the Lambda.
#   Supply var.lambda_arn when ready to wire the Lambda.
###############################################################################


###############################################################################
# DynamoDB Table
###############################################################################

resource "aws_dynamodb_table" "main" {
  name           = var.table_name
  billing_mode   = var.billing_mode
  read_capacity  = var.billing_mode == "PROVISIONED" ? var.read_capacity : null
  write_capacity = var.billing_mode == "PROVISIONED" ? var.write_capacity : null

  # Primary key
  hash_key  = "PK"
  range_key = "SK"

  attribute {
    name = "PK"
    type = "S"
  }

  attribute {
    name = "SK"
    type = "S"
  }

  # GSI — inverted key pattern (SK as hash, PK as range)
  global_secondary_index {
    name            = "GSI-SK-PK"
    hash_key        = "SK"
    range_key       = "PK"
    projection_type = "ALL"
    read_capacity   = var.billing_mode == "PROVISIONED" ? var.read_capacity : null
    write_capacity  = var.billing_mode == "PROVISIONED" ? var.write_capacity : null
  }

  # Stream — emit new + old images so the filter can inspect NewImage.
  stream_enabled   = true
  stream_view_type = "NEW_AND_OLD_IMAGES"

  point_in_time_recovery {
    enabled = var.enable_pitr
  }

  tags = merge(var.tags, { Name = var.table_name })
}

###############################################################################
# Event-Source Mapping (Stream → Lambda)
#
# Filter passes only records where NewImage.need_summary.BOOL is true.
# Records missing the attribute or set to false are dropped before
# the Lambda is invoked — no wasted executions.
###############################################################################

resource "aws_lambda_event_source_mapping" "dynamodb_stream" {
  count = var.trigger_lambda_arn != "" ? 1 : 0

  event_source_arn  = aws_dynamodb_table.main.stream_arn
  function_name     = var.trigger_lambda_arn
  starting_position = "LATEST"
  batch_size        = 100

  filter_criteria {
    filter {
      pattern = jsonencode({
        dynamodb = {
          NewImage = {
            need_summary = {
              BOOL = [true]
            }
          }
        }
      })
    }
  }

  depends_on = [aws_dynamodb_table.main]
}
