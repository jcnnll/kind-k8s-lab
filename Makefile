up:
	kind create cluster --config kind/cluster.yaml
	kubectl apply -f platform/namespaces/
	kubectl apply -f platform/limits/
	kubectl apply -f platform/quotas/
	kubectl apply -f platform/rbac/
	kubectl apply -f platform/ingress/

	$(MAKE) label-nodes
	$(MAKE) wait-ready
	$(MAKE) tls
	$(MAKE) deploy
	$(MAKE) validate

label-nodes:
	kubectl label node devops-lab-worker node-role.kubernetes.io/worker-1=true --overwrite
	kubectl label node devops-lab-worker2 node-role.kubernetes.io/worker-2=true --overwrite

wait-ready:
	kubectl wait --for=condition=Ready nodes --all --timeout=180s
	kubectl get ns lab >/dev/null
	kubectl get sa lab-agent -n lab >/dev/null
	kubectl wait --namespace ingress-nginx \
		--for=condition=available deployment/ingress-nginx-controller \
		--timeout=180s
	kubectl wait --namespace ingress-nginx \
		--for=condition=ready pod \
		-l app.kubernetes.io/component=controller \
		--timeout=180s

tls:
	./scripts/bootstrap-tls.sh

deploy: tls
	kubectl apply -f workloads/echo/deploy.yaml
	kubectl apply -f workloads/echo/ingress.yaml

validate:
	@echo "Validating ingress routing..."

	@success=0; \
	for i in $$(seq 1 30); do \
		if curl -sk https://api.lab | grep -q "hello lab"; then \
			echo "Ingress OK"; \
			success=1; \
			break; \
		fi; \
		echo "Waiting for ingress... ($$i/30)"; \
		sleep 2; \
	done; \
	if [ $$success -ne 1 ]; then \
		echo "Ingress validation FAILED"; \
		exit 1; \
	fi

down:
	kind delete cluster --name devops-lab

check:
	@echo "Checking platform state..."

	kubectl get ns lab >/dev/null
	kubectl get sa lab-agent -n lab >/dev/null
	kubectl get role lab-role -n lab >/dev/null
	kubectl get rolebinding lab-binding -n lab >/dev/null
	kubectl get resourcequota lab-quota -n lab >/dev/null
	kubectl get limitrange lab-default-limits -n lab >/dev/null

	@echo "Verifying RBAC behavior..."

	kubectl auth can-i list pods -n lab --as system:serviceaccount:lab:lab-agent 2>/dev/null | grep -q yes
	kubectl auth can-i list nodes --as system:serviceaccount:lab:lab-agent 2>/dev/null | grep -q no

	@echo "Checking nodes..."

	kubectl get nodes | grep -q Ready

	@echo "Checking ingress..."

	kubectl get ns ingress-nginx >/dev/null
	kubectl get deployment ingress-nginx-controller -n ingress-nginx >/dev/null
	kubectl get svc ingress-nginx-controller -n ingress-nginx >/dev/null

	@echo "CHECKS OUT FINE"
