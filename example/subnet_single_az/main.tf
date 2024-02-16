# 第七章 ネットワーク(マルチAZ化前)
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

# パブリックネットワーク
# パブリックサブネット
resource "aws_subnet" "example_public" {
  vpc_id = aws_vpc.example_vpc.id
  cidr_block = "10.0.0.0/24"
  # サブネットで起動したインスタンスにパブリックIPアドレスを自動的に割り当てるかどうか
  map_public_ip_on_launch = true
  availability_zone = "ap-northeast-1a"

	tags = {
    Name = "terraform_example_public_subnet"
  }
}

# ルートテーブルの関連付け
resource "aws_route_table_association" "example_public" {
	subnet_id = aws_subnet.example_public.id
	route_table_id = aws_route_table.example_public.id
}


# プライベートネットワーク
# プライベートサブネット
resource "aws_subnet" "example_private" {
	vpc_id = aws_vpc.example_vpc.id
	cidr_block = "10.0.64.0/24"
	availability_zone = "ap-northeast-1a"
	map_public_ip_on_launch = false

	tags = {
    	Name = "terraform_example_private_subnet"
  }
}

# プライベートサブネット用のルートテーブル
resource "aws_route_table" "example_private" {
	vpc_id = aws_vpc.example_vpc.id

	tags = {
		Name = "terraform_example_private_route_table"
	}
}

# ルートテーブルの関連付け
resource "aws_route_table_association" "example_private" {
	subnet_id = aws_subnet.example_private.id
	route_table_id = aws_route_table.example_private.id
}


# EIPとNATゲートウェイ(マルチAZ化前)
#EIP
resource "aws_eip" "example_nat_gateway" {
	# domain = "vpc"
	vpc = true
	depends_on = [aws_internet_gateway.terraform_example]
}

resource "aws_nat_gateway" "example_nat_gateway" {
	allocation_id = aws_eip.example_nat_gateway.id
	# パブリックサブネットを指定
	subnet_id = aws_subnet.example_public_0.id
	depends_on = [aws_internet_gateway.terraform_example]
}

# プライベートネットワークからインターネットへ通信するためのルート(マルチAZ化前)
resource "aws_route" "example_private" {
	route_table_id = aws_route_table.example_private.id
	nat_gateway_id = aws_nat_gateway.example_nat_gateway.id
	destination_cidr_block = "0.0.0.0/0"
}