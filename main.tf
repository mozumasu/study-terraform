provider "aws"{
	region="ap-northeast-1"
}

# ami (amazon machine image)の定義
# data リソース名 ラベル名
data "aws_ami" "recent_amazon_linux_2"{
	most_recent = true
	owners = ["amazon"]

	filter{
		name ="name"
		values =["amzn2-ami-hvm-2.0.*-x86_64-gp2"]
	}
	
	filter{
		name = "state"
		values = ["available"]
	}
}

# # リージョン一覧を取得するためのIAMロールを作成する

# リージョン一覧を取得するためのIAMポリシー
data "aws_iam_policy_document" "allow_describe_regions"{
	statement{
		effect = "Allow"
		actions = ["ec2:DescribeRegions"] #リージョン一覧を取得する
		resources = ["*"]
	}
}

# # リージョン一覧を取得するためのIAMポリシーを作成する
# resource "aws_iam_policy" "example"{
# 	name = "example"
# 	path = "/"
# 	policy = data.aws_iam_policy_document.allow_describe_regions.json
# }

# # リージョン一覧を取得するためのIAMロールを作成する
# data "aws_iam_policy_document" "ec2_assume_role"{
# 	statement{
# 		effect = "Allow"
# 		actions = ["sts:AssumeRole"]
# 		principals{
# 			type = "Service"
# 			identifiers = ["ec2.amazonaws.com"]
# 		}
# 	}
# }

# # リージョン一覧を取得するためのIAMロールを作成する
# resource "aws_iam_role" "example"{
# 	name = "example"
# 	assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
# }

# # リージョン一覧を取得するためのIAMロールとポリシーを紐付ける
# resource "aws_iam_role_policy_attachment" "example"{
# 	role = aws_iam_role.example.name
# 	policy_arn = aws_iam_policy.example.arn
# }

module "describe_regions_for_ec2"{
	source = "./iam_role"
	name = "describe-regions-for-ec2"
	identifier = "ec2.amazonaws.com"
	policy = data.aws_iam_policy_document.allow_describe_regions.json
}



# プライベートバケットの定義
resource "aws_s3_bucket" "private"{
	bucket = "private-pragmatic-terraform-mozumasu" #バケット名は一意にする

	versioning {
		enabled = true
	}


	server_side_encryption_configuration{
		rule{
			apply_server_side_encryption_by_default{
				sse_algorithm = "AES256"
				}
			}
		}
}

# ブロックパブリックアクセスの定義
resource "aws_s3_bucket_public_access_block" "private"{
	bucket = aws_s3_bucket.private.id
	block_public_acls = true
	block_public_policy = true
	ignore_public_acls = true
	restrict_public_buckets = true
}

#パブリックバケットの定義
resource "aws_s3_bucket" "public" {
	bucket = "public-pragmatic-terraform-mozumasu"
	# acl = "public-read"

	cors_rule{
		allowed_origins=["https://example.com"]
		allowed_methods=["GET"]
		allowed_headers=["*"]
		max_age_seconds=3000
	}
}

# ログバケット

# ログバケットの定義
resource "aws_s3_bucket" "alb_log" {
	bucket = "alb-log-pragmatic-terraform-mozumasu"

	lifecycle_rule{
		enabled = true
		expiration{
			days = 180
		}
	}
}


# バケットポリシー
# バケットポリシーの定義
resource "aws_s3_bucket_policy" "alb_log" {
	bucket = aws_s3_bucket.alb_log.id
	policy = data.aws_iam_policy_document.alb_log.json
}

data "aws_iam_policy_document" "alb_log"{
	statement {
		effect = "Allow"
		actions = ["s3:PutObject"]
		resources = ["arn:aws:s3:::${aws_s3_bucket.alb_log.id}/*"]

		principals {
			type = "AWS"
			identifiers = ["582318560864"]
		}
	}
}


locals {
	example_instance_type="t3.micro"
}

# EC2インスタンスの設定
resource "aws_instance" "example" {
	ami=data.aws_ami.recent_amazon_linux_2.image_id
	instance_type=local.example_instance_type
	vpc_security_group_ids=[aws_security_group.example_ec2.id]

	tags = {
		Name = "nekochan"
	}

	user_data = file("./user_data.sh")
}

# セキュリティグループの設定
resource "aws_security_group" "example_ec2"{
	name = "example-ec2"

	ingress{
		from_port=80
		to_port=80
		protocol="tcp"
		cidr_blocks=["0.0.0.0/0"]
	}

	egress{
		from_port=0
		to_port=0
		protocol="-1"
		cidr_blocks=["0.0.0.0/0"]
	}
}

#モジュールの利用
module "webserver"{
	source = "./http_server"
	instance_type = local.example_instance_type
}


output "example_instance_id"{
	value = aws_instance.example.id
}

# output "example_public_dns"{
# 	value = aws_instance.example.public_dns
# }
output "example_public_dns"{
	value = aws_instance.example.public_dns
}
