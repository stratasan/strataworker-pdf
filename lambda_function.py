# -*- coding: utf-8 -*-
# pylint: disable=superfluous-parens,F823,E501
import sys

sys.path.insert(0, './dist')
import os
from ast import literal_eval
import base64
import logging
import requests
import botocore
import json
import boto3
import subprocess
from raven import Client
import tempfile

from requests.packages.urllib3.exceptions import InsecureRequestWarning

requests.packages.urllib3.disable_warnings(InsecureRequestWarning)

s3_resource = boto3.resource('s3', endpoint_url=os.environ.get('ENDPOINT_URL'))
logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)


def s3_object_exists(s3_object):
    """ boto3 does not have an elegant way to see if an s3.Object
    already exists. This is a wrapper that returns True if it exists,
    or False if it does not. """
    try:
        s3_object.metadata
        return True
    except botocore.exceptions.ClientError:
        return False


def generate_user_report_pdf(url, bucket, filename, orientation='landscape', force=False):
    ''' Generates a PDF using a URL and stores it into s3

    Args:
        url: A url to the retrieve
        bucket: The S3 to store into
        filename: The full path in s3 to store as
        orientation: The orientation to use. Default: landscape
        force: Force overwrite if file exists in s3

    '''
    local_temp_file = tempfile.NamedTemporaryFile()
    cmd = f'/opt/bin/wkhtmltopdf --dpi 200 --javascript-delay 2000 --print-media-type -T 13mm -B 13mm -L 13mm -R 13mm -q -O {orientation} {url} -'

    # If we're not in debug mode and the file already exists, make use of it.
    extra_args = {
        'ACL': 'private',
        'StorageClass':
            'REDUCED_REDUNDANCY',
        'ContentType': 'application/pdf',
        'ServerSideEncryption': 'AES256'
    }

    s3_object = s3_resource.Object(bucket, filename)
    if not s3_object_exists(s3_object) or force:
        # Convert to PDF.
        try:
            converted_report = subprocess.check_output(cmd, shell=True)

        except subprocess.CalledProcessError as e:
            logger.info(
                'wkhtmltopdf throws exit status 2 if any page assets have issues. capture output anyway, continue.')
            if e.returncode == 2:
                converted_report = e.output
            elif e.returncode == 1 and b''.join([f'\x00{character}' for character in 'Syntellis']) in e.output:
                logger.info(
                    'There were errors, but we still got a usable PDF with the bytestring for "Syntellis" so no 403 or 404.')
                converted_report = e.output
            else:
                raise e
        try:
            with open(local_temp_file.name, 'wb') as f:
                f.write(converted_report)
            s3_resource.Bucket(bucket).upload_file(local_temp_file.name, filename, ExtraArgs=extra_args)
        except Exception as e:
            raise e


def lambda_handler(event, context):
    logger.info("Base64 encoded payload: %s", base64.b64encode(json.dumps(event).encode('ascii')))
    payload = event
    url = payload.get('url', None)
    if 'localhost' in url or '127.0.0.1' in url:
        logger.info(f'Cowardly quitting due to url: {url}')
        return None

    bucket = payload.get('bucket', None)
    filename = payload.get('filename', None)
    orientation = payload.get('orientation', 'landscape')
    force = literal_eval(payload.get('force', 'False'))
    generate_user_report_pdf(url=url, bucket=bucket, filename=filename, orientation=orientation, force=force)


if __name__ == '__main__':
    lambda_handler(json.loads(os.environ.get("AWS_LAMBDA_EVENT_BODY", "{}")), {})
