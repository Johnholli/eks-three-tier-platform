resource "random_password" "mongo" {
  length  = 24
  special = false
}

resource "aws_secretsmanager_secret" "mongo" {
  name                    = "workshop/mongo"
  recovery_window_in_days = 0 # lets you destroy/recreate without a 7-day name lock
  tags                    = local.tags
}

resource "aws_secretsmanager_secret_version" "mongo" {
  secret_id = aws_secretsmanager_secret.mongo.id
  secret_string = jsonencode({
    username = "admin"
    password = random_password.mongo.result
  })
}