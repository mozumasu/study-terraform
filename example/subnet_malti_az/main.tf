# 第七章 ネットワーク(マルチAZ化)
// VPC
resource "aws_vpc" "example_vpc" {
  cidr_block           = "10.0.0.0/16"
  // Amazon DNS サーバーを使用するかどうか
  enable_dns_support   = true
  // Amazon DNS ホスト名を使用するかどうか
  enable_dns_hostnames = true

  tags = {
    Name = "terraform_example_vpc"
  }
}

# インターネットゲートウェイ
resource "aws_internet_gateway" "terraform_example" {
  vpc_id = aws_vpc.example_vpc.id

  	tags = {
    Name = "terraform_example_internet_gateway"
  }
}

# パブリックサブネット
resource "aws_subnet" "example_public_0" {
	vpc_id = aws_vpc.example_vpc.id
	cidr_block = "10.0.1.0/24"
	availability_zone = "ap-northeast-1a"
	map_public_ip_on_launch = true

	tags = {
		Name = "terraform_example_public_subnet_0"
	}
}
resource "aws_subnet" "example_public_1" {
	vpc_id = aws_vpc.example_vpc.id
	cidr_block = "10.0.2.0/24"
	availability_zone = "ap-northeast-1c"
	map_public_ip_on_launch = true

	tags = {
		Name = "terraform_example_public_subnet_1"
	}
}

# ルートテーブルの関連付け
resource "aws_route_table_association" "example_public_0" {
	subnet_id = aws_subnet.example_public_0.id
	route_table_id = aws_route_table.example_public.id
}
resource "aws_route_table_association" "example_public_1" {
	subnet_id = aws_subnet.example_public_1.id
	route_table_id = aws_route_table.example_public.id
}

# ルートテーブル
resource "aws_route_table" "example_public" {
  vpc_id = aws_vpc.example_vpc.id

  tags = {
	Name = "terraform_example_public_route_table"
  }
}

# ルート
resource "aws_route" "example_public" {
	route_table_id = aws_route_table.example_public.id
	gateway_id = aws_internet_gateway.terraform_example.id
	destination_cidr_block = "0.0.0.0/0"
}

# プライベートサブネット
resource "aws_subnet" "example_private_0" {
	vpc_id = aws_vpc.example_vpc.id
	cidr_block = "10.0.65.0/24"
	availability_zone = "ap-northeast-1a"
	map_public_ip_on_launch = false

	tags = {
    	Name = "terraform_example_private_subnet_0"
  }
}
resource "aws_subnet" "example_private_1" {
	vpc_id = aws_vpc.example_vpc.id
	cidr_block = "10.0.66.0/24"
	availability_zone = "ap-northeast-1c"
	map_public_ip_on_launch = false

	tags = {
    	Name = "terraform_example_private_subnet_1"
  }
}

# プライベートサブネット用のルートテーブル
resource "aws_route_table" "example_private_0" {
	vpc_id = aws_vpc.example_vpc.id

	tags = {
		Name = "terraform_example_private_route_table_0"
	}
}
resource "aws_route_table" "example_private_1" {
	vpc_id = aws_vpc.example_vpc.id

	tags = {
		Name = "terraform_example_private_route_table_1"
	}
}

# マルチAZ化したプライベートサブネット用のルート
resource "aws_route" "example_private_0" {
	route_table_id = aws_route_table.example_private_0.id
	nat_gateway_id = aws_nat_gateway.example_nat_gateway_0.id
	destination_cidr_block = "0.0.0.0/0"
}
resource "aws_route" "example_private_1" {
	route_table_id = aws_route_table.example_private_1.id
	nat_gateway_id = aws_nat_gateway.example_nat_gateway_1.id
	destination_cidr_block = "0.0.0.0/0"
}

# ルートテーブルの関連付け
resource "aws_route_table_association" "example_private_0" {
	subnet_id = aws_subnet.example_private_0.id
	route_table_id = aws_route_table.example_private_0.id
}
resource "aws_route_table_association" "example_private_1" {
	subnet_id = aws_subnet.example_private_1.id
	route_table_id = aws_route_table.example_private_1.id
}

# EIPとNATゲートウェイ
#EIP
resource "aws_eip" "example_nat_gateway_0" {
	# domain = "vpc"
	vpc = true
	depends_on = [aws_internet_gateway.terraform_example]
}
resource "aws_eip" "example_nat_gateway_1" {
	# domain = "vpc"
	vpc = true
	depends_on = [aws_internet_gateway.terraform_example]
}
# NATゲートウェイ
resource "aws_nat_gateway" "example_nat_gateway_0" {
	allocation_id = aws_eip.example_nat_gateway_0.id
	subnet_id = aws_subnet.example_public_0.id
	depends_on = [aws_internet_gateway.terraform_example]
}
resource "aws_nat_gateway" "example_nat_gateway_1" {
	allocation_id = aws_eip.example_nat_gateway_1.id
	subnet_id = aws_subnet.example_public_1.id
	depends_on = [aws_internet_gateway.terraform_example]
}

