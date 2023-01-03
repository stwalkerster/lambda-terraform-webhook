.PHONY: clean requirements main

package: main requirements
	rm -f dist/function.zip
	cd dist/; zip -r function.zip ./*

dist:
	mkdir -p dist

main: dist main.py
	cp main.py dist/
	cp broker_ca.crt dist/

requirements: requirements.txt
	pip install --platform manylinux2014_x86_64 --target=dist --implementation cp --python 3.8 --only-binary=:all: --upgrade -r requirements.txt

clean:
	rm -rf dist/