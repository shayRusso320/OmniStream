###############################################################################
# Module: Database
###############################################################################

module "dynamodb" {
  source = "./infra/dynamodb"

  tags               = var.tags
  table_name         = var.table_name
  billing_mode       = var.billing_mode
  read_capacity      = var.read_capacity
  write_capacity     = var.write_capacity
  enable_pitr        = var.enable_pitr
  trigger_lambda_arn = var.trigger_lambda_arn
}

###############################################################################
# Module: Authentication
###############################################################################

module "cognito" {
  source = "./infra/cognito"

  tags                 = var.tags
  user_pool_name       = var.user_pool_name
  app_client_name      = var.app_client_name
  cognito_domain       = var.cognito_domain
  google_client_id     = var.google_client_id
  google_client_secret = var.google_client_secret
  callback_urls        = var.callback_urls
  logout_urls          = var.logout_urls

  lambda_post_confirmation_arn  = module.register_user.post_confirmation_lambda_arn
  lambda_post_confirmation_name = module.register_user.post_confirmation_lambda_name
}