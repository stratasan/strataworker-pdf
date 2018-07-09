install:
	if [ ! -d dist ]; then virtualenv dist; fi
	. dist/bin/activate
	pip install -r requirements.txt -t dist/ >/dev/null
	rm -rf dist/boto* #These push our lambda zip over the 50mb limit, boto is included in the container.

zip: install
	rm -rf lambda_strataworker_pdf.zip
	zip -r lambda_strataworker_pdf.zip lambda_function.py wkhtmltopdf dist/ >/dev/null

run:
	$(eval EVENT_BODY := "{\"url\": \"www.google.com\", \"bucket\": \"stratassets-test\", \"filename\": \"foo.pdf\", \"force\": \"True\"}")
	AWS_LAMBDA_EVENT_BODY=${EVENT_BODY} docker-compose run lambda

test:
	bats test.bats


clean:
	rm -rf dist
