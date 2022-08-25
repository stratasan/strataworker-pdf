install:
	if [ ! -d dist ]; then virtualenv dist; fi
	. dist/bin/activate
	pip install -r requirements.txt -t dist/ >/dev/null

zip: install
	rm -rf lambda_strataworker_pdf.zip
	zip -r lambda_strataworker_pdf.zip lambda_function.py wkhtmltox dist/ >/dev/null

run:
	$(eval EVENT_BODY := "{\"url\": \"www.google.com\", \"bucket\": \"stratassets-test\", \"filename\": \"foo.pdf\", \"force\": \"True\"}")
	AWS_LAMBDA_EVENT_BODY=${EVENT_BODY} AWS_DEFAULT_REGION=us-east-1 ENDPOINT_URL=http://localstack:4566 docker-compose run --use-aliases mocklambda

test:
	bats test.bats


clean:
	rm -rf dist
