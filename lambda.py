import os
from base64 import b64encode

import boto3

page_template = '<html><body><ul>{}</ul></body></html>'
list_template = '<li><a href="{path}">{name}</a>'

S3_BUCKET = os.environ.get('S3_BUCKET')

FILE_TYPES = {'egg', 'whl', 'gz'}

s3 = boto3.resource('s3')


def is_allowed_type(path):
    return os.path.splitext(path)[1][1:] in FILE_TYPES


def get_objects():
    bucket = s3.Bucket(S3_BUCKET)
    return {object.key: object for object in bucket.objects.all()}


def parse_path(path):
    package, *filename = path.split('/')
    return package, ''.join(filename)


def handler(event, context):
    objects = get_objects()

    path = event.get('path', '/')[1:]
    package, filename = parse_path(path)

    if package:

        if filename:

            # download file
            if path in objects and is_allowed_type(path):
                summary = objects[path]
                object = s3.Object(summary.bucket_name, summary.key)
                local_path = f'/tmp/{filename}'
                object.download_file(local_path)
                with open(local_path, 'rb') as file:
                    data = file.read()
                data = b64encode(data)
                return {
                    "isBase64Encoded": True,
                    "headers": {
                        "Content-Disposition": f"attachment; filename={filename}",
                        "Content-Type": "application/zip, application/octet-stream",
                    },
                    "body": data.decode()
                }
            else:
                raise Exception('Invalid file requested.')

        # list package files
        buffer = len(package) + 1

        items = {}
        for key in objects:
            print(package, key)
            filename = key[buffer:] if key.startswith(package) else key
            print(filename)
            if '/' not in filename and is_allowed_type(filename):
                items[filename] = filename

    else:

        # list packages
        items = {key: key for key in objects if key.endswith('/') and '/' not in key[:-1]}

    listing = sorted(list_template.format(path=key, name=value) for key, value in items.items())

    return {
        "isBase64Encoded": False,
        "headers": {"Content-Type": "text/html"},
        "body": page_template.format("\n".join(listing))
    }
