		#!/bin/bash
		# yum：Red Hatベースのシステムで使用されるパッケージマネージャー
		yum install -y httpd
		# Apache HTTP Serverを起動
		systemctl start httpd.service