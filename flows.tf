###############################################################################
# Module: Register User Flow
###############################################################################

module "register_user" {
  source                = "./flows/register_user"
  tags                  = var.tags
  table_name            = module.dynamodb.table_name
  table_arn             = module.dynamodb.table_arn
}
