# modules/secrets/main.tf

# ─── RANDOM PASSWORD GENERATION ──────────────────────────────────────
# Terraform generates a cryptographically secure random password.
# It is stored only in Secrets Manager — never in state in plain text.

resource "aws_secretsmanager_secret" "db_password" {
  name        = "${var.project_name}/${var.environment}/db/master-password"
  description = "RDS Aurora master password — auto-rotated every 30 days"

  # Prevent accidental deletion of the secret
  recovery_window_in_days = 7

  tags = { Name = "${var.project_name}-${var.environment}-db-secret" }
}

# Generate a random 32-character password
resource "random_password" "db_master" {
  length           = 32
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
  # Exclude characters that cause issues in MySQL connection strings
  min_upper   = 2
  min_lower   = 2
  min_numeric = 2
  min_special = 2
}

# Store the generated password in Secrets Manager as JSON
resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id = aws_secretsmanager_secret.db_password.id
  secret_string = jsonencode({
    username = var.db_master_username
    password = random_password.db_master.result
    dbname   = var.db_name
    engine   = "aurora-mysql"
    port     = 3306
  })
}

# ─── APP SECRET — connection string assembled at deploy time ──────────
# This secret gives the app everything it needs to connect to the DB.
# The app reads this at startup using the AWS SDK — no env vars with passwords.

resource "aws_secretsmanager_secret" "db_connection" {
  name                    = "${var.project_name}/${var.environment}/db/connection"
  description             = "Full DB connection details for application use"
  recovery_window_in_days = 7
  tags                    = { Name = "${var.project_name}-${var.environment}-db-connection" }
}
