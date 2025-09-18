PORT = 8000

serve:
	mkdocs serve -a 0.0.0.0:$(PORT)

build:
	mkdocs build --clean

deploy:
	mkdocs gh-deploy --force

clean:
	rm -rf site/
