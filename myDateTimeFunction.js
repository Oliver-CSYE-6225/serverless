'use strict';
const aws = require("aws-sdk");
const ses = new aws.SES();
const dynamodb = new aws.DynamoDB.DocumentClient();
aws.config.update({ region: "us-east-1" });
exports.handler = (event, context, callback) => {
    let message = JSON.parse(event.Records[0].Sns.Message);
    console.log(message.email + "test log");
    let searchParams = {
        TableName: "Email-Tokens",
        Key: {
        EmailId:message.email,
        }
    };
    dynamodb.get(searchParams, (err, resp) => {
        if(!err){
            let alive = true;
            if (resp.Item != null || resp.Item != undefined) {
                if (resp.Item.TimeToExist < +new Date()) {
                    console.log(resp.Item.TimeToExist);
                    console.log(+new Date());
                    alive = false;
                }
            } 
            // else {
            //     if (resp.Item.ttl > new Date().getTime()) {
            //         alive = true;
            //     }
            // }
            console.log("alive:", alive);
            if(alive){
                let currentTime = +new Date();
                let ttl = 5 * 60 * 1000;
                let expiry = currentTime + ttl;
                let params = {
                    Item: {
                        EmailId:message.email,
                        // token: context.awsRequestId,
                        Token: message.token,
                        TimeToExist: expiry
                    },
                    TableName: "Email-Tokens"
                };
            dynamodb.put(params, (err, data) => {
                if(!err){
                    let params = {
                        Destination: {
                            ToAddresses: [message.email],
                        },
                        Message: {
                            Body: {
                                Text: { Data: "Click the link to verify email for account creation\n\n" +
                                "http://prod.oliverrodrigues.me/v1/verifyUserEmail?email="+ message.email +"&token=" + message.token},
                            },
                            Subject: { Data: "Verify Email for Account Creation" },
                        },
                        Source: "noreply@prod.oliverrodrigues.me",
                    };
                    return ses.sendEmail(params).promise()
                } else {
                    console.log("Error");
                }
            })
            }
        } else {
            console.log("GET Request Failed");
        }
    })
  return context.logStreamName
}