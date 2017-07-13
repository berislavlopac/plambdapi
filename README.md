PλPI
====

**PλPI** (or `PlambdaPI`, which is a play on PyPI) is a simple tool to create an AWS-hosted,  [PEP 503](https://www.python.org/dev/peps/pep-0503/) compliant personal PyPI repository. It's using S3 bucket to host the repository, indexed using a Lambda function via an API Gateway.

Usage
-----

1. Install [Terraform](https://www.terraform.io/downloads.html) .
2. Make a ZIP file with the lambda code: `$ zip -r lambda.zip lambda.py`
3. Check terraform configuration: `$ terraform plan`
4. Execute terraform configuration: `$ terraform apply`
5. Upload your Python package file (egg, wheel and/or gzipped source) to the S3 bucket (creating directory if necessary)
6. Install the package anywhere using `pip install --extra-index-url=[api gateway's URL] [package-name]`

Upcoming
--------

* Better documentation
* Options to set up authorization on the API Gateway
* Script to automatically build and upload a Python package