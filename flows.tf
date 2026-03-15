###############################################################################
# Module: Register User Flow
###############################################################################

module "register_user" {
  source                = "./flows/register_user"
  tags                  = var.tags
  table_name            = module.dynamodb.table_name
  table_arn             = module.dynamodb.table_arn
}

module "add_user_topics" {
  source                    = "./flows/add_user_topics"
  tags                      = var.tags
  api_gateway_id            = module.api_gateway.api_id
  api_gateway_execution_arn = module.api_gateway.execution_arn
  dynamodb_table_arn        = module.dynamodb.table_arn
  cognito_jwt_authorizer_id = module.api_gateway.cognito_jwt_authorizer_id
  qdrant_api_key            = var.qdrant_api_key
  qdrant_url                = var.qdrant_url
  dynamodb_table_name       = module.dynamodb.table_name
  openai_api_key            = var.openai_api_key
}