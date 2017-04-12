//Save Manager
"use strict";
define(["aws-sdk-js"],

function(AWS){
	
	var saved_params,s3, bucket;
    console.log(AWS);


	var SaveManager = class {
		constructor(){

			AWS.config.region = 'us-east-1'; // Region
			var creds = new AWS.CognitoIdentityCredentials({
				IdentityPoolId: 'us-east-1:ae662e85-94d0-4dcf-81b5-9e27df28af8f'
			});
			AWS.config.credentials = creds;


			saved_params = {
				Bucket: 'dynabtest',
				Delimiter: '/',
				Prefix: 'saved_files/'
			};
			s3 = new AWS.S3();
			s3.listObjects(saved_params, function(error, data) {
				if (error) {
					console.log(error); // an error occurred

				} else {
					console.log("success", data.Contents);
					for (var i = 0; i < data.Contents.length; i++) {
						//var key = data.Contents[i].Key.split('/')[1].split('.txt')[0];
						//self.addFileToSelect(key, data.Contents[i].Key);
					}
				}
			});



			bucket = new AWS.S3({
				params: {
					Bucket: 'dynabtest'
				}
			});
		}

		saveFile(data,filename){
			var file = {
				Key: 'saved_files/' + filename + '.txt',
				Body: JSON.stringify(data),
				ACL: 'public-read-write'

			};
			bucket.upload(file, function(err, data) {
				var results = err ? 'ERROR!' : 'SAVED.';
				alert(results);
			});	



		}



	};
	return SaveManager;



});