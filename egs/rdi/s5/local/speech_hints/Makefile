PHONY: docker

docker:
	docker build --build-arg AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID} --build-arg AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY} -t workfit/kaldi:speechhints -f Dockerfile .
