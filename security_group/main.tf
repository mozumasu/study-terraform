# セキュリティグループのモジュール化
variable "name" {} # セキュリティグループ名
variable "vpc_id" {} # VPC ID
variable "port" {} # 通信を許可するポート番号
variable "cidr_blocks" {
	type = list(string)
} #　通信を許可するCIDRブロック

resource "aws_security_group" "default" {
	name        = var.name
	vpc_id      = var.vpc_id
}

resource "aws_security_group_rule" "ingress" {
	type = "ingress"
	from_port   = var.port
	to_port     = var.port
	protocol    = "tcp"
	cidr_blocks = var.cidr_blocks
	security_group_id = aws_security_group.default.id
}

resource "aws_security_group_rule" "egress" {
	type = "egress"
	from_port   = 0
	to_port     = 0
	protocol    = "-1"
	cidr_blocks = ["0.0.0.0/0"]
	security_group_id = aws_security_group.default.id
}

output "security_group_id" {
	value = aws_security_group.default.id
}