# Image Moderator for S3 Bucket — managed with Terraform on AWS

> Status :  in construction
  
<img src="docs/full-diagram.png" alt="image-moderator-diagram">

## Overview
  

`s3_image_moderator` is an AWS-based automation that scans images stored in an Amazon S3 bucket for 
inappropriate or unsafe content using Amazon Rekognition.
It runs automatically (e.g., every 24 hours) and notifies administrators when potential violations are found.

- EventBridge triggers a Lambda function on schedule.
- Lambda lists images in the S3 bucket.
- For each image, it calls Rekognition’s Moderation API.
- Detected issues (e.g., nudity, violence) are logged and sent to SNS for admin notification.
- Admins review flagged images, tag them as “OK” or “Flagged,” and optionally quarantine or delete violations.

## 🧰 Built with
- AWS S3 – image storage
- AWS Lambda (Python) – scanning logic
- Amazon Rekognition – unsafe content detection
- Amazon EventBridge – daily trigger
- Amazon SNS – notifications
- Terraform – infrastructure as code