import boto3
import json
import os
import re

rekognition = boto3.client('rekognition')
s3 = boto3.client('s3')
sns = boto3.client('sns')

def sanitize_tag_value(value: str) -> str:
    """Remove or replace invalid characters for S3 tags."""
    value = re.sub(r'[^a-zA-Z0-9 _.\-:]', '-', value)  # Replace invalid characters
    return value[:256]  # Trim to 256 chars (S3 tag limit)

def has_moderation_tag(bucket, key):
    """Return True if object already has a 'Moderation' tag."""
    try:
        tagging = s3.get_object_tagging(Bucket=bucket, Key=key)
        for tag in tagging.get('TagSet', []):
            if tag['Key'] == 'Moderation':
                return True
    except s3.exceptions.ClientError as e:
        # Ignore 404 or access issues and assume no tags
        if e.response['Error']['Code'] != 'NoSuchTagSet':
            raise
    return False

def handler(event, context):
    bucket = os.environ['BUCKET_NAME']
    topic_arn = os.environ['SNS_TOPIC_ARN']

    objects = s3.list_objects_v2(Bucket=bucket).get('Contents', [])
    flagged = []

    for obj in objects:
        key = obj['Key']

        # Skip if already tagged with Moderation
        if has_moderation_tag(bucket, key):
            print(f"Skipping already tagged object: {key}")
            continue

        # Run Rekognition moderation
        response = rekognition.detect_moderation_labels(
            Image={'S3Object': {'Bucket': bucket, 'Name': key}},
            MinConfidence=70
        )

        labels = [l['Name'] for l in response.get('ModerationLabels', [])]

        # Tag based on results
        if labels:
            flagged.append({'key': key, 'labels': labels})
            labels_value = sanitize_tag_value(','.join(labels))
            tag_set = [
                {'Key': 'Moderation', 'Value': 'Flagged'},
                {'Key': 'Labels', 'Value': labels_value}
            ]
        else:
            tag_set = [{'Key': 'Moderation', 'Value': 'Safe'}]

        s3.put_object_tagging(
            Bucket=bucket,
            Key=key,
            Tagging={'TagSet': tag_set}
        )

    # Notify if flagged images found
    if flagged:
        sns.publish(
            TopicArn=topic_arn,
            Subject="⚠️ Inappropriate Images Detected",
            Message=json.dumps(flagged, indent=2)
        )

    return {"Number of flagged objects": len(flagged)}
