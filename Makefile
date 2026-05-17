include .env

.PHONY: prereq secrets build install-jupyter up-small up-medium up-large down resize

prereq:
	bash scripts/00-prereq.sh

secrets:
	kubectl apply -f k8s/00-namespaces.yaml
	kubectl apply -f k8s/01-jupyter-auth-secret.yaml
	kubectl apply -f k8s/02-spark-s3-secret.yaml

build:
	bash scripts/01-build-images.sh

install-jupyter:
	bash scripts/02-install-jupyterhub.sh

up-small:
	bash scripts/03-cluster-up.sh small data-exp-small

up-medium:
	bash scripts/03-cluster-up.sh medium data-exp-medium

up-large:
	bash scripts/03-cluster-up.sh large data-exp-large

down:
	bash scripts/04-cluster-down.sh data-exp-medium

resize:
	bash scripts/05-cluster-resize.sh data-exp-medium 4
