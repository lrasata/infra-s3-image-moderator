import boto3, json, os

rekognition = boto3.client('rekognition')
s3 = boto3.client('s3')
sns = boto3.client('sns')

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

    if flagged:
        sns.publish(
            TopicArn=topic_arn,
            Subject="⚠️ Inappropriate Images Detected",
            Message=json.dumps(flagged, indent=2)
        )

    return {"flagged_count": len(flagged)}
