.PHONY: clean requirements

package: main.py requirements
	rm -f dist/function.zip
	cd dist/; zip -r function.zip ./*

dist:
	mkdir -p dist

main.py: dist
	cp main.py dist/

requirements: requirements.txt
	pip install --platform manylinux2014_x86_64 --target=dist --implementation cp --python 3.8 --only-binary=:all: --upgrade -r requirements.txt

clean:
	rm -rf dist/