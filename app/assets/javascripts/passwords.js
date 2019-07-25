// # Place all the behaviors and hooks related to the matching controller here.
// # All this logic will automatically be available in application.js.
// # You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

var oldTextSave;

// Save settings from inputs in Cookies
function saveExpirations()
{
	days_value  = $("#password_expire_after_time").val();
	views_value = $("#password_expire_after_views").val();
	dbv         = $("#password_deletable_by_viewer").is(":checked")

	Cookies.set('pwpush_days',  days_value, { expires: 365 });
	Cookies.set('pwpush_views', views_value, { expires: 365 });
	Cookies.set('pwpush_dbv', dbv.toString(), { expires: 365 });
	
	$("#btnSaveExpirations").text("Saved!");
	setTimeout( function(){
		$("#btnSaveExpirations").text(oldTextSave);
	}, 1500);
}

// Load settings from Cookies in inputs
function loadExpirations()
{
	if(typeof Cookies.get("pwpush_days") != "undefined")
	{
		$("#password_expire_after_time").val(Cookies.get("pwpush_days"));
	}
	
	if(typeof Cookies.get("pwpush_views") != "undefined")
	{
		$("#password_expire_after_views").val(Cookies.get("pwpush_views"));
	}
	
	if(typeof Cookies.get("pwpush_dbv") != "undefined")
	{
		$("#password_deletable_by_viewer").prop('checked', Cookies.get("pwpush_dbv")=="true");
	}
	
}

// Set the default setting in the inputs. Can be overwritten from loadExpirations()
function setDefaultSettings()
{
	$("#password_expire_after_time").val(1);
	$("#password_expire_after_views").val(1);
	$("#password_deletable_by_viewer").prop('checked', true);
	
	// Payload is Empty
	$("#btnSubmit").prop("disabled", true);
}

// Cheach the payload is valide
function validatePayload(){
	if($("#password_payload").val().length > 250)
	{
		$("#btnSubmit").prop("disabled", true);
		$("#alertPayloadError").fadeIn();
	}
	else if($("#password_payload").val().length == 0)
	{
		$("#btnSubmit").prop("disabled", true);
		$("#alertPayloadError").fadeOut();
	}
	else
	{
		$("#btnSubmit").prop("disabled", false);
		$("#alertPayloadError").fadeOut();
	}
}

function sendSecret()
{
	var secret = $("#password_payload").val();
	cipherObject = encryptSecret(secret);
	
	var data = "";
	data += "uft8=%E2%9C%93&"; // encodeURI for ✓
	data += "authenticity_token=" + encodeURI($('meta[name=csrf-token]').attr("content")) + "&";
	data += "password[payload]=" + encodeURI(cipherObject.payload) + "&";
	data += "password[expire_after_time]=" + $("#password_expire_after_time").val() + "&";
	data += "password[expire_after_views]=" + $("#password_expire_after_views").val();
	if($("#password_deletable_by_viewer").is(":checked"))
	{
		data += "&password[deletable_by_viewer]=on";
	}
	
	$.ajax({
		type:    "POST",
		url:     "/p",
		data:    data,
		success: function(data) {
			var response = JSON.parse(data);
			if(response.success == 1)
			{
				createLink(cipherObject, response.token)
			}
			else
			{
				$("#alertPostdError").fadeIn();
			}
		},
		error:   function(jqXHR, textStatus, errorThrown) {
			$("#alertPostdError").fadeIn();
		}
	});
}

function createLink(cipherObject, linkToken)
{
	var port = location.post == 80 || location.port == 443 ? "" : ":" + location.port;
	var newLink = location.protocol + "//" + window.location.hostname + port + "/p/";
	newLink += linkToken;
	newLink += "#";
	
	// format: url...#key;iv;padding
	
	for(var i in cipherObject.key)
	{
		var hex = cipherObject.key[i].toString(16);
		newLink += hex.length == 2 ? hex : "0" + hex;
	}
	
	newLink += ";"
	
	for(var j in cipherObject.iv)
	{
		var hex = cipherObject.iv[j].toString(16);
		newLink += hex.length == 2 ? hex : "0" + hex;
	}
	
	newLink += ";" + cipherObject.padding;
	window.location.href=newLink;
}

$(document).ready(function() {
	// On start
	setDefaultSettings();
	loadExpirations();
	
	// Events
	$("#btnSaveExpirations").click(function(){
		saveExpirations();
	});
	$('#password_payload').on('input', function () {
		validatePayload();
	});
	
	$("#btnSubmit").click(function(){
		sendSecret();
	});
	
	$("#new_password").submit(function(e){
        e.preventDefault();
		sendSecret();
    });
	
	oldTextSave = $("#btnSaveExpirations").text();
	
});
