# # -----------------
# # SSM Parameter Store
# # -----------
# resource "aws_ssm_parameter" "host" {
#   name  = "${var.project}/${var.environment}/app/MYSQL_HOST"
#   type  = "String"
#   value = aws_db_instance.mysql_standalone.address
# }

# resource "aws_ssm_parameter" "port" {
#   name  = "${var.project}/${var.environment}/app/MYSQL_PORT"
#   type  = "String"
#   value = aws_db_instance.mysql_standalone.port
# }

# resource "aws_ssm_parameter" "database" {
#   name  = "${var.project}/${var.environment}/app/MYSQL_DATABASE"
#   type  = "String"
#   value = aws_db_instance.mysql_standalone.db_name
# }

# resource "aws_ssm_parameter" "username" {
#   name  = "${var.project}/${var.environment}/app/MYSQL_USERNAME"
#   type  = "SecureString"
#   value = aws_db_instance.mysql_standalone.username
# }

# resource "aws_ssm_parameter" "password" {
#   name  = "${var.project}/${var.environment}/app/MYSQL_PASSWORD"
#   type  = "SecureString"
#   value = aws_db_instance.mysql_standalone.password
# }

# # -----------------
# # key apair
# # -----------
resource "aws_key_pair" "keypair" {
  key_name   = "${var.project}-${var.environment}-keypair"
  public_key = file("./src/tastylog-dev-keypair.pub")

  tags = {
    Name    = "${var.project}-${var.environment}-keypair"
    Project = var.project
    Env     = var.environment
  }
}

# # -----------------
# # EC2 Instance
# # -----------
resource "aws_instance" "app_server" {
  ami                         = data.aws_ami.app.id
  instance_type               = "t2.micro"
  iam_instance_profile        = aws_iam_instance_profile.app_ec2_profile.name
  key_name                    = aws_key_pair.keypair.key_name
  subnet_id                   = aws_subnet.public_subnet_1a.id
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.app_sg.id, aws_security_group.opmng_sg.id]

  tags = {
    Name    = "${var.project}-${var.environment}-app-ec2"
    Project = var.project
    Env     = var.environment
    Type    = "app"
  }
}

# # -----------------
# # launch configuration
# # -----------
resource "aws_launch_template" "app_lt" {
  update_default_version = true

  name          = "${var.project}-${var.environment}-app-lt"
  image_id      = data.aws_ami.app.id
  instance_type = "t2.micro"
  key_name      = aws_key_pair.keypair.key_name

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name    = "${var.project}-${var.environment}-app-ec2"
      Project = var.project
      Env     = var.environment
      Type    = "app"
    }
  }

  network_interfaces {
    associate_public_ip_address = true
    device_index                = 0
    subnet_id                   = aws_subnet.public_subnet_1a.id
    security_groups             = [aws_security_group.app_sg.id, aws_security_group.opmng_sg.id]
    delete_on_termination       = true
  }
  iam_instance_profile {
    name = aws_iam_instance_profile.app_ec2_profile.name
  }

  // 起動時に実行するスクリプト
  # user_data = {
  # }

}
