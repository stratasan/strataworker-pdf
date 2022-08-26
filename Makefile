.DEFAULT_GOAL:=help

install: 	## Setup the dist requirements
	if [ ! -d dist ]; then python -m venv dist; fi
	. dist/bin/activate
	pip install -r requirements.txt -t dist/ >/dev/null

zip: install 	## Build the distribution zip
	rm -rf lambda_strataworker_pdf.zip
	zip -r lambda_strataworker_pdf.zip lambda_function.py dist/ >/dev/null

run: 	## Run the mocklambda container for manually debugging
	$(eval EVENT_BODY := "{\"url\": \"www.google.com\", \"bucket\": \"stratassets-test\", \"filename\": \"foo.pdf\", \"force\": \"True\"}")
	AWS_LAMBDA_EVENT_BODY=${EVENT_BODY} AWS_DEFAULT_REGION=us-east-1 ENDPOINT_URL=http://localstack:4566 docker-compose run --use-aliases mocklambda

test: 	## Run the automated tests
	bats test.bats

clean: 	## Clean up the virtualenv, dist, and wkhtmltox directories
	rm -rf dist venv wkhtmltox

get_wkhtmltox: 	## Get the wkhtmltox lambda zip and expact it for use locally
	rm -rf wkhtmltox
	curl -LO https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6-4/wkhtmltox-0.12.6-4.amazonlinux2_lambda.zip
	unzip wkhtmltox-0.12.6-4.amazonlinux2_lambda.zip -d wkhtmltox
	rm -f wkhtmltox-0.12.6-4.amazonlinux2_lambda.zip

dev_prep: clean get_wkhtmltox 	## Prep your virtual environment
	if [ ! -d venv ]; then python -m venv venv; fi
	. venv/bin/activate
	pip install -r requirements.txt

package: install zip 	## Setup the dist requirements and create the lambda zip file

prep_deploy: ## Nasatarts use to copy for terraform deployment in health
	mkdir -p ../health/terraform/prod/pdf_worker/strataworker-pdf
	cp lambda_strataworker_pdf.zip ../health/terraform/prod/pdf_worker/strataworker-pdf/lambda_strataworker_pdf.zip

help: 	# Print help on Makefile
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n\nTargets:\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)