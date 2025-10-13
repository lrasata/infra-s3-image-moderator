import boto3, json, os, re

rekognition = boto3.client('rekognition')
s3 = boto3.client('s3')
sns = boto3.client('sns')

def sanitize_tag_value(value: str) -> str:
    """Remove or replace invalid characters for S3 tags."""
    # Replace any invalid characters with a dash
    value = re.sub(r'[^a-zA-Z0-9 _.\-:]', '-', value)
    # Trim to 256 characters
    return value[:256]

# Detect inappropriate images in S3 bucket
def handler(event, context):
    bucket = os.environ['BUCKET_NAME']
    topic_arn = os.environ['SNS_TOPIC_ARN']

    objects = s3.list_objects_v2(Bucket=bucket).get('Contents', [])
    flagged = []

    for obj in objects:
        key = obj['Key']
        response = rekognition.detect_moderation_labels(
            Image={'S3Object': {'Bucket': bucket, 'Name': key}}
        )
        labels = [l['Name'] for l in response['ModerationLabels']]

        if labels:
            flagged.append({'key': key, 'labels': labels})

            # Tag the S3 object
            labels_value = sanitize_tag_value(','.join(labels))
            tag_set = [
                {'Key': 'Moderation', 'Value': 'Flagged'},
                {'Key': 'Labels', 'Value': labels_value}
            ]

            s3.put_object_tagging(
                Bucket=bucket,
                Key=key,
                Tagging={'TagSet': tag_set}
            )

    if flagged:
        sns.publish(
            TopicArn=topic_arn,
            Subject="⚠️ Inappropriate Images Detected",
            Message=json.dumps(flagged, indent=2)
        )

    return {"Number of flagged objects": len(flagged)}
