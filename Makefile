install:
	if [ ! -d dist ]; then python -m venv dist; fi
	. dist/bin/activate
	pip install -r requirements.txt -t dist/ >/dev/null

zip: install
	rm -rf lambda_strataworker_pdf.zip
	zip -r lambda_strataworker_pdf.zip lambda_function.py dist/ >/dev/null

run:
	$(eval EVENT_BODY := "{\"url\": \"www.google.com\", \"bucket\": \"stratassets-test\", \"filename\": \"foo.pdf\", \"force\": \"True\"}")
	AWS_LAMBDA_EVENT_BODY=${EVENT_BODY} AWS_DEFAULT_REGION=us-east-1 ENDPOINT_URL=http://localstack:4566 docker-compose run --use-aliases mocklambda

test:
	bats test.bats

clean:
	rm -rf dist venv wkhtmltox

get_wkhtmltox:
	rm -rf wkhtmltox
	curl -LO https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6-4/wkhtmltox-0.12.6-4.amazonlinux2_lambda.zip
	unzip wkhtmltox-0.12.6-4.amazonlinux2_lambda.zip -d wkhtmltox
	rm -f wkhtmltox-0.12.6-4.amazonlinux2_lambda.zip

dev_prep: clean get_wkhtmltox
	if [ ! -d venv ]; then python -m venv venv; fi
	. venv/bin/activate
	pip install -r requirements.txt

package: install zip

prep_deploy:
	mkdir -p ../health/terraform/prod/pdf_worker/strataworker-pdf
	cp lambda_strataworker_pdf.zip ../health/terraform/prod/pdf_worker/strataworker-pdf/lambda_strataworker_pdf.zip
