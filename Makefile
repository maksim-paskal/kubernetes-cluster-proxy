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
	# cluster001
	# 
	kubectl --kubeconfig=${HOME}/.kube/dev  create configmap master-certs \
	--from-file=ssl/server.crt \
	--from-file=ssl/server.key \
	--from-file=ssl/ca.crt || true
	kubectl --kubeconfig=${HOME}/.kube/dev create configmap cluster001-certs \
	--from-file=ssl/client01.crt \
	--from-file=ssl/client01.key || true
	kubectl --kubeconfig=${HOME}/.kube/dev create configmap cluster002-certs \
	--from-file=ssl/client01.crt \
	--from-file=ssl/client01.key || true

	kubectl --kubeconfig=${HOME}/.kube/dev apply -f master.yaml
	kubectl --kubeconfig=${HOME}/.kube/dev apply -f cluster001.yaml
	kubectl --kubeconfig=${HOME}/.kube/dev apply -f cluster002.yaml

	# cluster002
	# 
	kubectl --kubeconfig=${HOME}/.kube/dev-slave-01 create configmap master-certs \
	--from-file=ssl/server.crt \
	--from-file=ssl/server.key \
	--from-file=ssl/ca.crt || true
	kubectl --kubeconfig=${HOME}/.kube/dev-slave-01 create configmap cluster001-certs \
	--from-file=ssl/client01.crt \
	--from-file=ssl/client01.key || true
	kubectl --kubeconfig=${HOME}/.kube/dev-slave-01 create configmap cluster002-certs \
	--from-file=ssl/client01.crt \
	--from-file=ssl/client01.key || true

	kubectl --kubeconfig=${HOME}/.kube/dev-slave-01 apply -f master.yaml
	kubectl --kubeconfig=${HOME}/.kube/dev-slave-01 apply -f cluster001.yaml
	kubectl --kubeconfig=${HOME}/.kube/dev-slave-01 apply -f cluster002.yaml

	# restart clients
	kubectl --kubeconfig=${HOME}/.kube/dev delete pod -lapp=master-proxy || true
	kubectl --kubeconfig=${HOME}/.kube/dev delete pod -lapp=cluster001 || true
	kubectl --kubeconfig=${HOME}/.kube/dev delete pod -lapp=cluster002 || true
	kubectl --kubeconfig=${HOME}/.kube/dev-slave-01 delete pod -lapp=master-proxy || true
	kubectl --kubeconfig=${HOME}/.kube/dev-slave-01 delete pod -lapp=cluster001 || true
	kubectl --kubeconfig=${HOME}/.kube/dev-slave-01 delete pod -lapp=cluster002 || true

	# get external urls
	@echo cluster001 `kubectl --kubeconfig=${HOME}/.kube/dev get svc master-proxy --template="{{range .status.loadBalancer.ingress}}{{.hostname}}{{end}}"`
	@echo cluster002 `kubectl --kubeconfig=${HOME}/.kube/dev-slave-01 get svc master-proxy --template="{{range .status.loadBalancer.ingress}}{{.hostname}}{{end}}"`
	
	# coredns
	kubectl --kubeconfig=${HOME}/.kube/dev-slave-01 apply -f coredns/corefile.yaml
	kubectl --kubeconfig=${HOME}/.kube/dev-slave-01 -n kube-system delete pod -lk8s-app=kube-dns

	# test
	# apt update && apt install -y dnsutils curl
	# 
	# curl https443.kubernetes.default.svc.cluster.local.global
clean:
	kubectl --kubeconfig=${HOME}/.kube/dev delete configmap master-certs
	kubectl --kubeconfig=${HOME}/.kube/dev delete configmap cluster001-certs
	kubectl --kubeconfig=${HOME}/.kube/dev delete configmap cluster002-certs
	kubectl --kubeconfig=${HOME}/.kube/dev delete -f master.yaml
	kubectl --kubeconfig=${HOME}/.kube/dev delete -f cluster001.yaml
	kubectl --kubeconfig=${HOME}/.kube/dev delete -f cluster002.yaml

	kubectl --kubeconfig=${HOME}/.kube/dev-slave-01 delete configmap master-certs
	kubectl --kubeconfig=${HOME}/.kube/dev-slave-01 delete configmap cluster001-certs
	kubectl --kubeconfig=${HOME}/.kube/dev-slave-01 delete configmap cluster002-certs
	kubectl --kubeconfig=${HOME}/.kube/dev-slave-01 delete -f master.yaml
	kubectl --kubeconfig=${HOME}/.kube/dev-slave-01 delete -f cluster001.yaml
	kubectl --kubeconfig=${HOME}/.kube/dev-slave-01 delete -f cluster002.yaml