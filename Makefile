NAME1 = nodemono2_app1

.PHONY: build1
build1:
	@DOCKER_BUILDKIT=1 docker build . -f packages/app1/Dockerfile -t $(NAME1)

.PHONY: start1
start1:
	@docker run -p 127.0.0.1:3000:3000/tcp -d --name $(NAME1) $(NAME1)

.PHONY: check1
check1:
	@curl --retry 5 --retry-all-errors  http://localhost:3000/

.PHONY: stop1
stop1:
	@docker kill $(NAME1)
	@docker rm $(NAME1)

.PHONY: test1
test1: build1 start1 check1 stop1

#########################################

NAME2 = nodemono2_next

.PHONY: build2
build2:
	@DOCKER_BUILDKIT=1 docker build . -f packages/next-app/Dockerfile -t $(NAME2)

.PHONY: start2
start2:
	@docker run -p 0.0.0.0:59000:3000/tcp -d --name $(NAME2) $(NAME2)

.PHONY: stop2
stop2:
	@docker kill $(NAME2)
	@docker rm $(NAME2)
