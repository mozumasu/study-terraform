variable "instance_type" {}

# EC2インスタンスを作成するためのリソースを定義
resource "aws_instance" "default" {
    ami = "ami-0c3fd0f5d33134a76"
    # セキュリティグループ:インスタンスへのネットワークアクセスを制御するための仮想ファイアウォールのようなもの
    vpc_security_group_ids = [aws_security_group.default.id]
    # インスタンスタイプ:インスタンスのハードウェア構成を定義する
    instance_type = var.instance_type

    # ユーザデータ:インスタンス起動時に実行するスクリプト
    user_data = file("./user_data.sh")
}

resource "aws_security_group" "default" {
    name = "ec2"

    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

output "instance_id" {
    value = aws_instance.default.id
}

output "public_dns" {
    value = aws_instance.default.public_dns
}