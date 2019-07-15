// This is a manifest file that'll be compiled into including all the files listed below.
// Add new JavaScript/Coffee code in separate files in this directory and they'll automatically
// be included in the compiled file accessible from http://example.com/assets/application.js
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// the compiled file.
//
//= require jquery3
//= require jquery_ujs
//= require popper
//= require bootstrap-sprockets
//= require_tree ./libs
//= require_tree ./sh

var counterToggle = 0;

// Hide the Password after 10 Seconds again
function hidePassword(element, checkNumber)
{
	setTimeout(function(){
		// If false, the button is clicked again. So a other function on the
		// stack wait 10 seconds to hide the password
		if(counterToggle == checkNumber)
		{
			var id = $(element).attr("toggle");
			if($(id).attr("type")== "text")
			{
				$(id).attr("type", "password")
			}
			adjustTooltipText(element);
		}
	}, 10000);
}

function adjustTooltipText(element)
{
	var id = $(element).attr("toggle");
	if($(id).attr("type")== "text")
	{
		$(element).attr("data-original-title", "Hide the secret");
	}
	else
	{
		$(element).attr("data-original-title", "Show the secret for 10 seconds");
	}
}

// Used für AES Key and IV (16 Bytes)
function crateRandonNumber(length)
{
	randomArray = []
	for (var i = 0; i < length; i++)
	{
		var randomNumber = window.crypto.getRandomValues(new Uint32Array(1))[0];
		var randomByte = (randomNumber % 256);
		randomArray.push(randomByte);
	}
	return randomArray;
}

// Used to fill secret to length % 16 = 0
function getRandomChars(length)
{
	randomString = "";
	while(randomString.length < length)
	{
		randomString += window.crypto.getRandomValues(new Uint32Array(1))[0].toString(36);
	}
	return randomString.substring(0,length);
}

// Calculate the length of the packagedding
function getPaddingLength(secret)
{
	return 16 - (secret.length % 16)
}

// key should be 16, 24 or 32 bytes
// iv has to be 16 bytes
function encryptSecret(secret)
{
	var base64Secret = btoa(secret)	;
	cipherObject = 
	{
		key: crateRandonNumber(24),
		iv: crateRandonNumber(16),
		padding: getPaddingLength(base64Secret),
		payload: "-1"
	}
	
	var secretWithPadding =  getRandomChars(cipherObject.padding) + base64Secret;
	var textBytes = aesjs.utils.utf8.toBytes(secretWithPadding);
	var aesCbc = new aesjs.ModeOfOperation.cbc(cipherObject.key, cipherObject.iv);
	var encryptedBytes = aesCbc.encrypt(textBytes);
	cipherObject.payload = aesjs.utils.hex.fromBytes(encryptedBytes);
	return cipherObject;
}

// key should be 16, 24 or 32 bytes
// iv has to be 16 bytes
function decryptSecret(cipherObject)
{
	var encryptedBytes = aesjs.utils.hex.toBytes(cipherObject.payload);
	var aesCbc = new aesjs.ModeOfOperation.cbc(cipherObject.key, cipherObject.iv);
	var decryptedBytes = aesCbc.decrypt(encryptedBytes);
	var secretWithPadding = aesjs.utils.utf8.fromBytes(decryptedBytes);
	var base64Secret = secretWithPadding.substring(cipherObject.padding, secretWithPadding.length);
	return atob(base64Secret);
}


// Hide the alerts (on start the alerts are hidden with the class d-none. Must removed to slideIn())
function prepareAlerts()
{
	$(".first-hidden-alert").hide();
	$(".first-hidden-alert").removeClass("d-none");
	$(".first-hidden-alert").removeClass("first-hidden-alert");
}

$(document).ready(function() {
	
	prepareAlerts();
	
	// Events
	$(".toggle-password").click(function(){
		counterToggle++;
		hidePassword(this, counterToggle);
		adjustTooltipText(this);
	});
	
});