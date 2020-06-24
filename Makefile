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
	helm lint --strict multi-cluster-proxy/
	helm template multi-cluster-proxy/ | kubectl --kubeconfig=${HOME}/.kube/dev apply -f -
	helm template multi-cluster-proxy/ | kubectl --kubeconfig=${HOME}/.kube/dev-slave-01 apply -f -

	sleep 5
	# get external urls
	@echo cluster001 `kubectl --kubeconfig=${HOME}/.kube/dev get svc master-proxy --template="{{range .status.loadBalancer.ingress}}{{.hostname}}{{end}}"`
	@echo cluster002 `kubectl --kubeconfig=${HOME}/.kube/dev-slave-01 get svc master-proxy --template="{{range .status.loadBalancer.ingress}}{{.hostname}}{{end}}"`

	# test
	# apt update && apt install -y dnsutils curl
	# 
	# curl https443.kubernetes.default.svc.cluster.local.global
clean:
	helm template multi-cluster-proxy/ | kubectl --kubeconfig=${HOME}/.kube/dev delete -f - || true
	helm template multi-cluster-proxy/ | kubectl --kubeconfig=${HOME}/.kube/dev-slave-01 delete -f - || true
template:
	helm lint --strict multi-cluster-proxy/
	helm template multi-cluster-proxy/ | kubectl apply --dry-run --validate -f -