###############################################################################
# Module: Database
###############################################################################

module "dynamodb" {
  source = "./infra/dynamodb"

  tags               = var.tags
  table_name         = "OmniStreamTable"
  billing_mode       = "PROVISIONED"
  read_capacity      = 5
  write_capacity     = 5
  enable_pitr        = false
  trigger_lambda_arn = ""
}

###############################################################################
# Module: Authentication
###############################################################################

module "cognito" {
  source = "./infra/cognito"

  tags                 = var.tags
  user_pool_name       = "OmniStreamUserPool"
  app_client_name      = "OmniStreamAppClient"
  cognito_domain       = "omni-stream-auth"
  google_client_id     = var.google_client_id
  google_client_secret = var.google_client_secret
  callback_urls        = var.callback_urls
  logout_urls          = var.logout_urls

  lambda_post_confirmation_arn  = module.register_user.post_confirmation_lambda_arn
  lambda_post_confirmation_name = module.register_user.post_confirmation_lambda_name
}

module "api_gateway" {
    source = "./infra/gateway"
    
    tags                        = var.tags
    api_name                    = "omnistream-api"
    cognito_user_pool_id        = module.cognito.user_pool_id
    cognito_user_pool_client_id = module.cognito.app_client_id
    cors_allowed_origins        = ["*"] # Tighten to your domain in production.
    cors_allowed_methods        = ["GET", "POST", "OPTIONS"]
    cors_allowed_headers        = ["Authorization", "Content-Type"]
}