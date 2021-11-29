'use strict';
var aws = require("aws-sdk");
var ses = new aws.SES({ region: "us-east-1" });
exports.handler = function(event, context, callback) {
  console.log("Received event: ", event);
  var data = {
      "greetings": "Hellos, " + event.firstName + " " + event.lastName + "."
  };

  // callback(null, data);

  var params = {
    Destination: {
      ToAddresses: ["oliverrodrigues996@gmail.com"],
    },
    Message: {
      Body: {
        Text: { Data: "Test Oliver" },
      },

      Subject: { Data: "Test Email Oliver" },
    },
    Source: "oliver.r@prod.oliverrodrigues.me",
  };
 
  return ses.sendEmail(params).promise()
}