import subprocess
import os
import boto3
from boto3.s3.transfer import S3Transfer
import botocore
from raven import Client
import tempfile
import click

raven_client = None  # client = Client('https://80bd8f1c684244d3a6eefd1f2bda0f03:7402e5fa424548248afafc53bfa4e34d@sentry.io/8726')


def s3_resource():
    """ Return the S3 resource from boto3 """
    return boto3.resource('s3')


def s3_object_exists(s3_object):
    """ boto3 does not have an elegant way to see if an s3.Object
    already exists. This is a wrapper that returns True if it exists,
    or False if it does not. """
    try:
        s3_object.metadata
        return True
    except botocore.exceptions.ClientError:
        return False


@click.command()
@click.argument('url')
@click.argument('bucket_name')
@click.argument('filepath')
@click.option('--orientation', default='landscape', help='Type of orientation. Can be "landscape" or "portrait"')
@click.option('--force', '-f', is_flag=True, help='Force run even if file exists in destination')
def generate_user_report_pdf(url, bucket_name, filepath, orientation='landscape', force=False):
    """ Generates a PDF using a token based report view url and stores in it the assets.stratasan.com bucket on S3 """

    s3_object = s3_resource().Object(bucket_name, filepath)
    exists_already = False
    if s3_object_exists(s3_object) and not force:
        exists_already = True

    temp_file, temp_filename = tempfile.mkstemp()
    cmd_template = '/usr/local/bin/wkhtmltopdf --dpi 200 --javascript-delay 2000 --print-media-type -T 13mm -B 13mm -L 13mm -R 13mm -q -O {orientation} {url} {temp_filename}'
    cmd = cmd_template.format(url=url, orientation=orientation, temp_filename=temp_filename)
    print(cmd)

    # If we're not in debug mode and the file already exists, make use of it.
    if not exists_already:
        # Convert to PDF.
        converted_report = ''
        try:
            converted_report = subprocess.check_output(cmd, shell=True)

        except subprocess.CalledProcessError as e:
            # wkhtmltopdf throws exit status 2 if any page assets have issues. capture output anyway, continue.
            if e.returncode == 2:
                pass
            else:
                raven_client.captureException()
                return False

        try:
            print('temp_file is {}'.format(temp_file))
            print('temp_filename is {}'.format(temp_filename))
            print('bucket is {}'.format(bucket_name))
            print('filepath is {}'.format(filepath))
            client = s3_resource().meta.client
            transfer = S3Transfer(client)
            transfer.upload_file(temp_filename, bucket_name, filepath, extra_args={'StorageClass': 'REDUCED_REDUNDANCY', 'ServerSideEncryption': 'AES255'})
        except Exception:
            raven_client.captureException()
            return False

    return True


if __name__ == '__main__':
    generate_user_report_pdf()
