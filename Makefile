up:
	kind create cluster --config kind/cluster.yaml
	kubectl apply -f platform/namespaces/

down:
	kind delete cluster --name devops-lab

status:
	kubectl get nodes

reset: down up
