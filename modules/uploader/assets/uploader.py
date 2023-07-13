import boto3
import zipfile
import io
import mimetypes

s3 = boto3.client('s3')

def lambda_handler(event, context):
    print(event)
    src_bucket = event['artifact_src_bucket_name']
    src_key = event['artifact_src_bucket_path']
    dst_bucket = event['artifact_dst_bucket_name']
    dst_prefix = event['artifact_dst_bucket_path']

    # download zip file
    zip_obj = s3.get_object(Bucket=src_bucket, Key=src_key)
    zip_data = zip_obj['Body'].read()

    zip_file = io.BytesIO(zip_data)
    with zipfile.ZipFile(zip_file, 'r') as z:
        for filename in z.namelist():
            # skip if file is a directory
            if filename.endswith('/'):
                continue
            file_data = z.read(filename)
            content_type = mimetypes.guess_type(filename)[0] or 'application/octet-stream'
            s3.put_object(Body=file_data, Bucket=dst_bucket, Key=dst_prefix + filename, ContentType=content_type)
