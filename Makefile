VERSION:=$(shell cat VERSION)
BIN_DIR=_output/bin
RELEASE_DIR=_output/release
REL_OSARCH=amd64 arm64
REL_OS=linux
REPO=hwdef

clean:
	rm -rf _output

bin: clean
	for arch in ${REL_OSARCH}; do\
		CGO_ENABLED=0 GOOS=linux GOARCH=$$arch go build -o=${BIN_DIR}/$$arch/${REL_OS}/demo;\
	done

images: bin
	for arch in ${REL_OSARCH}; do\
		docker buildx build -t ${REPO}/demo:${VERSION}-${REL_OS}-$$arch --no-cache --platform linux/$$arch -f Dockerfile.$$arch . ;\
	done

push: images
	for arch in ${REL_OSARCH}; do\
		docker push ${REPO}/demo:${VERSION}-${REL_OS}-$$arch;\
	done

release: images
	mkdir -p ${RELEASE_DIR}
	for arch in ${REL_OSARCH}; do\
		docker save -o ${RELEASE_DIR}/demo-${REL_OS}-$$arch.tar ${REPO}/demo:${VERSION}-${REL_OS}-$$arch ;\
	done

create-multi-archimages: push
	docker manifest create ${REPO}/demo:${VERSION} ${REPO}/demo:${VERSION}-${REL_OS}-arm64 ${REPO}/demo:${VERSION}-${REL_OS}-amd64 ${REPO}/demo:${VERSION}-win-amd64

push-multi-archimages: create-multi-archimages
	docker manifest push ${REPO}/demo:${VERSION}
