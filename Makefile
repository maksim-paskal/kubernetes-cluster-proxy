init:
	@./init.ssl
test:
	curl -k --key ssl/client01.key --cert ssl/client01.crt https://aba859c73ec444e97876b7f7b9af975a-2ed373467ecf9fca.elb.us-east-1.amazonaws.com:30001