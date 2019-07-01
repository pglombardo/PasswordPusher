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

// Hide the alerts (on start the alerts are hidden with the class d-none. Must removed to slideIn())
function prepareAlertExpirationsSaved()
{
	$(".first-hidden-alert").hide();
	$(".first-hidden-alert").removeClass("d-none");
	$(".first-hidden-alert").removeClass("first-hidden-alert");
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

$(document).ready(function() {
	// On start
	setDefaultSettings();
	loadExpirations();
	prepareAlertExpirationsSaved()
	
	// Events
	$("#btnSaveExpirations").click(function(){
		saveExpirations();
	});
	$('#password_payload').on('input', function () {
		validatePayload();
	});
	
	oldTextSave = $("#btnSaveExpirations").text();
	
});
