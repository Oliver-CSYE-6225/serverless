
data "aws_sns_topic" "verify-user" {
  name = "verify-user"
}

resource "aws_iam_role" "iam_for_lambda" {
  name = "iam-for-lambda"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_lambda_function" "test-lambda" {
  filename      = "userVerification.zip"
  function_name = "userVerification"
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "userVerification.handler"

  # The filebase64sha256() function is available in Terraform 0.11.12 and later
  # For Terraform 0.11.11 and earlier, use the base64sha256() function and the file() function:
  # source_code_hash = "${base64sha256(file("lambda_function_payload.zip"))}"
  // source_code_hash = filebase64sha256("lambda_function_payload.zip")

  runtime = "nodejs14.x"

  environment {
    variables = {
      foo = "bar"
    }
  }
}

resource "aws_sns_topic_subscription" "sns-lambda-subscription" {
  topic_arn = data.aws_sns_topic.verify-user.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.test-lambda.arn
}

resource "aws_lambda_permission" "with_sns" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.test-lambda.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = data.aws_sns_topic.verify-user.arn
}


resource "aws_iam_policy" "Lambda-SES-Policy" {
  name        = "lambda-ses"
  description = "lambda-ses"


  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "ses:SendEmail",
          "ses:SendRawEmail"
        ],
        "Resource" : "*"
      }
    ]
  })

}

resource "aws_iam_role_policy_attachment" "attach-lambda-ses" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = aws_iam_policy.Lambda-SES-Policy.arn
}



resource "aws_iam_policy" "Lambda-Artifact-S3" {
  name        = "Lambda-Artifact-S3"
  description = "Lambda-Artifact-S3"


  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : [
          "s3:Get*",
          "s3:List*"
        ],
        "Effect" : "Allow",
        "Resource" : [
          aws_s3_bucket.lambda_bucket.arn,
          format("%s%s", aws_s3_bucket.lambda_bucket.arn, "/*")
        ]
    }]
  })
}

resource "aws_iam_role_policy_attachment" "attach-lambda-s3" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = aws_iam_policy.Lambda-Artifact-S3.arn
}


data "aws_iam_policy" "lambda-dynamo" {
  name = "Web-App-Dynamo"
}

resource "aws_iam_role_policy_attachment" "attach-lambda-dynamo" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = data.aws_iam_policy.lambda-dynamo.arn
}


data "aws_iam_role" "s3_access" {
  name = "EC2-CSYE6225"
}


resource "aws_iam_policy" "EC2-Publish-SNS" {
  name        = "EC2-Publish-SNS"
  description = "EC2-Publish-SNS"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    "Version" = "2012-10-17",
    "Statement" : [{
          "Effect" : "Allow",
          "Action" : "sns:Publish",
          "Resource" : data.aws_sns_topic.verify-user.arn
        }]    
  })
}

// resource "aws_iam_role" "lambda_service_role" {
//   name = "lambda-service-role"

//   assume_role_policy = <<EOF
// {
//   "Version": "2012-10-17",
//   "Statement": [
//     {
//       "Sid": "",
//       "Effect": "Allow",
//       "Principal": {
//         "Service": [
//           "lambda.amazonaws.com"
//         ]
//       },
//       "Action": "sts:AssumeRole"
//     }
//   ]
// }
// EOF
// }




//Policy that provides permissions to upload artifact to S3
resource "aws_iam_policy" "GH-Upload-To-S3" {
  name        = "GH-Serverless-Upload-To-S3"
  description = "GH-Serverless-Upload-To-S3"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    "Version" = "2012-10-17",
    "Statement" = [
      {
        "Effect" = "Allow",
        "Action" = [
          "s3:PutObject",
          "s3:Get*",
          "s3:List*"
        ],
        "Resource" = [
          aws_s3_bucket.lambda_bucket.arn,
          format("%s%s", aws_s3_bucket.lambda_bucket.arn, "/*")
        ]
      }
    ]
  })
}

resource "aws_iam_policy" "GH-Lambda" {
  name        = "GH-Lambda"
  description = "GH-Lambda"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    "Version" = "2012-10-17",
    "Statement" = [
      {
        "Effect" = "Allow",
        "Action" = [
          "lambda:UpdateFunctionCode",
          "lambda:UpdateFunctionConfiguration"
        ],
        "Resource" = "arn:aws:lambda:us-east-1:546679085257:function:userVerification"
      }
    ]
  })
}

resource "aws_iam_policy" "Lambda-Cloudwatch" {
  name        = "Lambda-Cloudwatch"
  description = "Lambda-Cloudwatch"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "logs:CreateLogGroup",
            "Resource": "*"
        },

        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": "*"
        }
    ]
})
}


resource "aws_iam_role_policy_attachment" "attach-Lambda-Cloudwatch" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = aws_iam_policy.Lambda-Cloudwatch.arn
}


resource "aws_iam_policy_attachment" "attach-GH-lambda" {
  name       = "test-attachment"
  users      = ["ghactions-serverless"]
  policy_arn = aws_iam_policy.GH-Lambda.arn
}



resource "aws_iam_policy" "GH-Code-Deploy" {
  name        = "GH-Serverless-Code-Deploy"
  description = "GH-Serverless-Code-Deploy"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "codedeploy:RegisterApplicationRevision",
          "codedeploy:GetApplicationRevision"
        ],
        "Resource" : [
          format("%s%s%s%s%s%s", "arn:aws:codedeploy:", var.aws_region, ":", var.aws_account_id, ":application:", var.codedeploy_application_name)
        ]
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "codedeploy:CreateDeployment",
          "codedeploy:GetDeployment"
        ],
        "Resource" : [
          "arn:aws:codedeploy:${var.aws_region}:${var.aws_account_id}:deploymentgroup:${var.codedeploy_application_name}/${var.codedeploy_deployment_group}"
        ]
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "codedeploy:GetDeploymentConfig"
        ],
        "Resource" : [
          "arn:aws:codedeploy:${var.aws_region}:${var.aws_account_id}:deploymentconfig:CodeDeployDefault.OneAtATime",
          "arn:aws:codedeploy:${var.aws_region}:${var.aws_account_id}:deploymentconfig:CodeDeployDefault.HalfAtATime",
          "arn:aws:codedeploy:${var.aws_region}:${var.aws_account_id}:deploymentconfig:CodeDeployDefault.LambdaAllAtOnce"
        ]
      }
    ]
  })
}

//Give S3 upload permissions to ghactions-serverless user
resource "aws_iam_policy_attachment" "attach-s3-upload" {
  name       = "test-attachment"
  users      = ["ghactions-serverless"]
  policy_arn = aws_iam_policy.GH-Upload-To-S3.arn
}

//Give permissions to allow ghactions-serverless to communicate with codedeploy 
resource "aws_iam_policy_attachment" "attach-code-deploy" {
  name       = "test-attachment"
  users      = ["ghactions-serverless"]
  policy_arn = aws_iam_policy.GH-Code-Deploy.arn
}

  resource "random_string" "prefix_lambda" {
  upper   = false
  lower   = true
  special = false
  length  = 5
}

resource "aws_s3_bucket" "lambda_bucket" {
  // depends_on = [aws_kms_key.kms_encryption_key]

  bucket        = format("%s%s%s", random_string.prefix_lambda.result, ".", "lambda.prod.oliverrodrigues.me")
  acl           = "private"
  force_destroy = true
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "aws:kms"
      }
    }
  }

  lifecycle_rule {
    enabled = true
    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }
  }
}

// // resource "aws_iam_role" "gh_actions_role" {
// //   depends_on          = [aws_iam_policy.GH-Upload-To-S3, aws_iam_policy.GH-Code-Deploy]
// //   name                = var.gh_actions_role_name
// //   managed_policy_arns = [aws_iam_policy.GH-Upload-To-S3.arn, aws_iam_policy.GH-Code-Deploy.arn]
// //   assume_role_policy = jsonencode({
// //     "Version" : "2012-10-17",
// //     "Statement" : [
// //       {
// //         "Effect" : "Allow",
// //         "Principal" : { "AWS" : "arn:aws:iam::746774523931:user/ghactions-serverless" },
// //         "Action" : "sts:AssumeRole"
// //       }
// //     ]
// //   })
// // }


// //Create a service role for codedeploy
// resource "aws_iam_role" "codedeploy_service_role" {
//   name = "codedeploy-service-role"

//   assume_role_policy = <<EOF
// {
//   "Version": "2012-10-17",
//   "Statement": [
//     {
//       "Sid": "",
//       "Effect": "Allow",
//       "Principal": {
//         "Service": [
//           "codedeploy.amazonaws.com"
//         ]
//       },
//       "Action": "sts:AssumeRole"
//     }
//   ]
// }
// EOF
// }

// //Attach policies to give codedeploy access to lambda and ec2 deployment
// resource "aws_iam_role_policy_attachment" "codedeploy_service_policy_attach" {
//   role       =  aws_iam_role.codedeploy_service_role.name
//   policy_arn = "arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole"
// }

// resource "aws_iam_role_policy_attachment" "codedeploy_lambda_policy_attach" {
//   role       =  aws_iam_role.codedeploy_service_role.name
//   policy_arn = "arn:aws:iam::aws:policy/service-role/AWSCodeDeployRoleForLambda"
// }

// resource "aws_iam_role_policy_attachment" "attach_ec2-s3" {
//   role       = aws_iam_role.codedeploy_service_role.name
//   policy_arn = aws_iam_policy.CodeDeploy-EC2-S3.arn
// }


// //Create codedeploy app
// resource "aws_codedeploy_app" "codedeploy_serverless" {
//   compute_platform = "Lambda"
//   name             = "csye6225-serverless"
// }



// //Create codedeploy deployment group
// resource "aws_codedeploy_deployment_group" "codedeploy_group" {
//   depends_on = [aws_codedeploy_app.codedeploy_serverless]
//   app_name               = "csye6225-serverless"
//   deployment_group_name = "csye6225-serverless-deployment"
//   service_role_arn       = aws_iam_role.codedeploy_service_role.arn
//   deployment_config_name = "CodeDeployDefault.LambdaAllAtOnce"

//   deployment_style {
//     deployment_option = "WITH_TRAFFIC_CONTROL"
//     deployment_type   = "BLUE_GREEN"
//   }


//   // autoscaling_groups = ["webapp_autoscale_group"]

//   auto_rollback_configuration {
//     enabled = true
//     events  = ["DEPLOYMENT_FAILURE"]
//   }

//   // ec2_tag_filter {
//   //   key = "instance_identifier"
//   //   type = "KEY_AND_VALUE"
//   //   value = "webapp_deploy"
//   // }
// }

