testCerts:
	openssl rsa -check -in ssl/ca.key
	openssl x509 -text -noout -in ssl/ca.crt
	openssl rsa -check -in ssl/client01.key
	openssl x509 -text -noout -in ssl/client01.crt
init:
	@./init.ssl
testLocal:
	curl -H "Host: http80.test.cluster1" localhost:4444?test
	curl -H "Host: https443.test-ssl.cluster1" localhost:4444?test
test:
	curl -k --key ssl/client01.key --cert ssl/client01.crt https://aba859c73ec444e97876b7f7b9af975a-2ed373467ecf9fca.elb.us-east-1.amazonaws.com:20000
deploy:
	kubectl --kubeconfig=${HOME}/.kube/dev create configmap nginx-certs \
	--from-file=ssl/server.crt \
	--from-file=ssl/server.key \
	--from-file=ssl/ca.crt || true

	kubectl --kubeconfig=${HOME}/.kube/dev apply -f master.yaml

	kubectl --kubeconfig=${HOME}/.kube/dev-slave-01 create configmap nginx-certs \
	--from-file=ssl/client01.crt \
	--from-file=ssl/client01.key || true
	kubectl --kubeconfig=${HOME}/.kube/dev-slave-01 apply -f slave.yaml