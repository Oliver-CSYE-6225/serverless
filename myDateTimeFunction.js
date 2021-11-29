'use strict';
    
exports.handler = function(event, context, callback) {
  console.log("Received event: ", event);
  var data = {
      "greetings": "Hellos, " + event.firstName + " " + event.lastName + "."
  };
  callback(null, data);
}