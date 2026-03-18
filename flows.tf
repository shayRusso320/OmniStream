###############################################################################
# Module: Register User Flow
###############################################################################

module "register_user" {
  source = "./flows/register_user"

  tags                  = var.tags
  table_name            = module.dynamodb.table_name
  table_arn             = module.dynamodb.table_arn
  artifacts_bucket_name = module.lambda_artifacts.artifacts_bucket_name
  artifact_key          = module.lambda_artifacts.artifact_key
}

module "add_user_topics" {
  source = "./flows/add_user_topics"

  tags                  = var.tags
  dynamodb_table_arn    = module.dynamodb.table_arn
  qdrant_api_key        = var.qdrant_api_key
  qdrant_url            = var.qdrant_url
  dynamodb_table_name   = module.dynamodb.table_name
  openai_api_key        = var.openai_api_key
  artifacts_bucket_name = module.lambda_artifacts.artifacts_bucket_name
  artifact_key          = module.lambda_artifacts.artifact_key
}