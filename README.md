# strataworker-pdf
Queue based worker for generating PDFs from the Syntellis app into S3 
using the wkhtmltox Lambda Layer zip.

Help is also available in the Makefile by running `make`

# Development Setup
We're going to:
- Download the expected version of the lambda layer for wkhmltox (wkhtmltopdf) 
- Setup a virtualenv
- Install python dependencies

```shell
make dev_prep
```

# Running locally with localstack, SAM and Docker Compose
- Start localstack with a `docker-compose up`
- Run the test lambda environment with a `make run`

**NOTE:** This just drops you in the container so you can run the lambda as you wish

# Running Tests
To run tests you need the bats and pdfinfo commands, which you can install like this:

```shell
git clone https://github.com/sstephenson/bats.git
cd bats
./install.sh /usr/local
brew install xpdf
```

To execute the tests:
```shell
bats test.bats
```

# Packaging the lamabda
- Run `make package`

# Deploying (General Concept)
- Setup add a lambda layer for the wkhtmltox zip file
- Setup a lambda for the lambda_stratawork_pdf.zip code using the wkhtmltox layer

**NOTE:** Make sure to add the following environment variable to the lambda
- LD_LIBRARY_PATH=/opt/lib
- FONTCONFIG_PATH=/opt/fonts

## Nasatarts Deployment
Assuming you have the health repo cloned into the parent directory of this one:
- `make prep_deploy` to copy the file to the proper terraform location
- Go to the prod pdf_lambda terraform in health and apply it.
