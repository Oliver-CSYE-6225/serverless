resource "aws_iam_policy" "CodeDeploy-EC2-S3" {
  name        = var.ec2_codedeploy_policy_name
  description = var.ec2_codedeploy_policy_name_description


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
          var.artifact_s3_arn,
          format("%s%s", var.artifact_s3_arn, "/*")
        ]
    }]
  })
}

// data "aws_iam_role" "s3_access" {
//   name = "EC2-CSYE6225"
// }

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
  name        = var.s3_artifact_upload_policy_name
  description = var.s3_artifact_upload_description

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
          var.artifact_s3_arn,
          format("%s%s", var.artifact_s3_arn, "/*")
        ]
      }
    ]
  })
}



resource "aws_iam_policy" "GH-Code-Deploy" {
  name        = var.ghactions_codedeploy_policy_name
  description = var.ghactions_codedeploy_policy_description

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



// resource "aws_iam_role" "gh_actions_role" {
//   depends_on          = [aws_iam_policy.GH-Upload-To-S3, aws_iam_policy.GH-Code-Deploy]
//   name                = var.gh_actions_role_name
//   managed_policy_arns = [aws_iam_policy.GH-Upload-To-S3.arn, aws_iam_policy.GH-Code-Deploy.arn]
//   assume_role_policy = jsonencode({
//     "Version" : "2012-10-17",
//     "Statement" : [
//       {
//         "Effect" : "Allow",
//         "Principal" : { "AWS" : "arn:aws:iam::746774523931:user/ghactions-serverless" },
//         "Action" : "sts:AssumeRole"
//       }
//     ]
//   })
// }


//Create a service role for codedeploy
resource "aws_iam_role" "codedeploy_service_role" {
  name = "codedeploy-service-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": [
          "codedeploy.amazonaws.com"
        ]
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

//Attach policies to give codedeploy access to lambda and ec2 deployment
resource "aws_iam_role_policy_attachment" "codedeploy_service_policy_attach" {
  role       =  aws_iam_role.codedeploy_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole"
}

resource "aws_iam_role_policy_attachment" "codedeploy_lambda_policy_attach" {
  role       =  aws_iam_role.codedeploy_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSCodeDeployRoleForLambda"
}

resource "aws_iam_role_policy_attachment" "attach_ec2-s3" {
  role       = aws_iam_role.codedeploy_service_role.name
  policy_arn = aws_iam_policy.CodeDeploy-EC2-S3.arn
}


//Create codedeploy app
resource "aws_codedeploy_app" "codedeploy_serverless" {
  compute_platform = "Lambda"
  name             = "csye6225-serverless"
}



//Create codedeploy deployment group
resource "aws_codedeploy_deployment_group" "codedeploy_group" {
  depends_on = [aws_codedeploy_app.codedeploy_serverless]
  app_name               = "csye6225-serverless"
  deployment_group_name = "csye6225-serverless-deployment"
  service_role_arn       = aws_iam_role.codedeploy_service_role.arn
  deployment_config_name = "CodeDeployDefault.LambdaAllAtOnce"

  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "BLUE_GREEN"
  }


  // autoscaling_groups = ["webapp_autoscale_group"]

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }

  // ec2_tag_filter {
  //   key = "instance_identifier"
  //   type = "KEY_AND_VALUE"
  //   value = "webapp_deploy"
  // }
}

