var oldTextUrl;
var oldTextRPayload;

function copyUrlInClipboard()
{
	$("#url").select();
	document.execCommand("copy");
	
	$("#btnCopyUrl").text("URL copied!");
	setTimeout(function(){
		$("#btnCopyUrl").text(oldTextUrl);
	}, 1500);
	
}

function copyPayloadInClipboard()
{
	$("#payload").attr("type","text");
	$("#payload").select();
	document.execCommand("copy");
	$("#payload").attr("type","password");
	
	$("#btnCopyPayload").text("Password copied!");
	setTimeout(function(){
		$("#btnCopyPayload").text(oldTextRPayload);
	}, 1500);
}

$(document).ready(function() {
	
	// Events
	$("#btnCopyUrl").click(function(){
		copyUrlInClipboard();
	});
	$('#btnCopyPayload').click(function () {
		copyPayloadInClipboard();
	});
	
	oldTextUrl = $("#btnCopyUrl").text();
	oldTextRPayload = $("#btnCopyPayload").text();
	
});