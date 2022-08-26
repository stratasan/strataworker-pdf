# strataworker-pdf
Queue based worker for generating PDFs from the Stratasan app into S3 
using the wkhtmltox Lambda Layer zip.

# Running locally with localstack, SAM and Docker Compose
- Start localstack with a `docker-compose up`
- Run the test lambda with a `make run`

# Packaging the lamabda
- Run `make package`

# Deploying (General Concept)
- Setup add a lambda layer for the wkhtmltox zip file
- Setup a lambda for the lambda_stratawork_pdf.zip code using the wkhtmltox layer

**NOTE:** Make sure to add the following environment variable to the lambda
- LD_LIBRARY_PATH=/opt/lib
- FONTCONFIG_PATH=/opt/fonts

# Nasatarts Deployment
Assuming you have the health repo cloned into the parent directory of this one:
- `make prep_deploy` to copy the file to the proper terraform location
- Go to the prod pdf_lambda terraform in health and apply it.

# Development Setup
We're going to:
- Download the expected version of the lambda layer for wkhmltox (wkhtmltopdf) 
- Setup a virtualenv
- Install python dependencies

```shell
make dev_prep
```

## Next to run tests you need the bats and pdfinfo commands
```shell
git clone https://github.com/sstephenson/bats.git
cd bats
./install.sh /usr/local
brew install xpdf
```
