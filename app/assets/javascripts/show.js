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

function decryptPayload()
{
	try
	{
		var hash = window.location.hash;
		if (hash == "")
		{
			return
		}
		var parts = hash.replace("#","").split(";");
		
		var keyHex = parts[0]
		var keyArray = []
		
		while(keyHex != "")
		{
			var singleByte = parseInt(keyHex.substring(0,2), 16)
			keyArray.push(singleByte);
			keyHex = keyHex.slice(2)
		}
		
		var ivHex = parts[1]
		var ivArray = []
		
		while(ivHex != "")
		{
			var singleByte = parseInt(ivHex.substring(0,2), 16)
			ivArray.push(singleByte);
			ivHex = ivHex.slice(2)
		}
		
		cipherObject = 
		{
			key: keyArray,
			iv: ivArray,
			padding: parts[2],
			payload: $("#payload").val()
		}
		secret = decryptSecret(cipherObject);
		$("#payload").val(secret);
	}
	catch (error)
	{
		$("#payload").val("");
		$("#alertPostdError").fadeIn();
	}
}

function setFullLinknInput()
{
	var fullUrl = $("#url").val() + window.location.hash;
	$("#url").val(fullUrl);
}


$(document).ready(function(){
	
	// Events
	$("#btnCopyUrl").click(function(){
		copyUrlInClipboard();
	});
	$('#btnCopyPayload').click(function () {
		copyPayloadInClipboard();
	});
	
	$("#form-show-payload").submit(function(e){
        e.preventDefault();
    });
	
	oldTextUrl = $("#btnCopyUrl").text();
	oldTextRPayload = $("#btnCopyPayload").text();
	
	decryptPayload();
	setFullLinknInput();
	
});
