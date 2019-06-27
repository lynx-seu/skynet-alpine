
REPO=lynx94/skynet
TAG=latest

build:
	docker build . -t $(REPO):$(TAG)

push: build
	docker push $(REPO):$(TAG)

clean:
	docker image rm -f $(REPO):$(TAG)
	docker container prune -f
