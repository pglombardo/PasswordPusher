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
	
	$("#btnCopyPayload").text("Secret copied!");
	setTimeout(function(){
		$("#btnCopyPayload").text(oldTextRPayload);
	}, 1500);
}

function decryptPayload()
{
	try
	{
		var hash = window.location.hash;
		
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
		disableValueCahnges();
	}
	catch (error)
	{
		$("#payload").val("");
		$("#alertPostdError").fadeIn();
		$("#pTimeUntilClear").hide();
	}
}

function disableValueCahnges()
{
	var originalValue = $("#payload").val();
	$('#payload').on('input', function () {
		$(this).val(originalValue);
	});
}

function setFullLinknInput()
{
	var fullUrl = $("#url").val() + window.location.hash;
	$("#url").val(fullUrl);
}

function setFocus()
{
	if($("#btnCopyUrl").length)
	{
		$("#btnCopyUrl").focus();
	}
	else
	{
		$("#btnCopyPayload").focus();
	}
}

function startCountdownToClear()
{
	if($("#pTimeUntilClear").length != 0)
	{
		var secondsUntilClear = $("#spanCountdown").attr("data-countdown");
		countDownToClear(secondsUntilClear);
	}
}

function countDownToClear(secondsUntilClear)
{
	window.setTimeout(function(){
		var newCountdown = secondsUntilClear - 1;
		updateCountdownHtml(newCountdown);
		if(newCountdown > 0)
		{
			countDownToClear(newCountdown);
		}
		else
		{
			clearSecret();
		}
	},1000);
}

function updateCountdownHtml(countdown)
{
	var seconds = countdown % 60;
	var minutes = (countdown - seconds) / 60;
	var formatedCountdown = (minutes > 9 ? minutes : "0" + minutes) + ":" + (seconds > 9 ? seconds : "0" + seconds);
	var formatedCountdown = minutes + ":" + (seconds > 9 ? seconds : "0" + seconds);
	$("#spanCountdown").text(formatedCountdown);
	
	if(countdown <= 60)
	{
		$("#spanCountdown").addClass("countdownWarning");
	}
}

function clearSecret()
{
	$("#pTimeUntilClear").text("Time's up! The secret is cleard!");
	$("#pTimeUntilClear").addClass("countdownWarning");
	$("#payload").val("");
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
	
	setFocus();
	
	startCountdownToClear();
});
