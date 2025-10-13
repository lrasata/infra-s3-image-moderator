import boto3
import os

s3 = boto3.client('s3')

# Source and quarantine bucket names
SOURCE_BUCKET = os.environ['SOURCE_BUCKET']
QUARANTINE_BUCKET = os.environ['QUARANTINE_BUCKET']

def is_flagged(bucket, key):
    """Check if object has Moderation=Flagged tag"""
    try:
        tagging = s3.get_object_tagging(Bucket=bucket, Key=key)
        for tag in tagging.get('TagSet', []):
            if tag['Key'] == 'Moderation' and tag['Value'] == 'Flagged':
                return True
    except s3.exceptions.ClientError as e:
        if e.response['Error']['Code'] != 'NoSuchTagSet':
            raise
    return False

def move_to_quarantine(bucket, key):
    """Copy object to quarantine bucket and delete original"""
    copy_source = {'Bucket': bucket, 'Key': key}
    s3.copy_object(CopySource=copy_source, Bucket=QUARANTINE_BUCKET, Key=key)
    s3.delete_object(Bucket=bucket, Key=key)
    print(f"Moved {key} to {QUARANTINE_BUCKET}")

def handler(event, context):
    # List all objects in source bucket
    objects = s3.list_objects_v2(Bucket=SOURCE_BUCKET).get('Contents', [])
    count = 0
    for obj in objects:
        key = obj['Key']
        if is_flagged(SOURCE_BUCKET, key):
            count += 1
            move_to_quarantine(SOURCE_BUCKET, key)
    return {"Number of moved objects": count}