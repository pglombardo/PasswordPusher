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

$(document).ready(function() {
	
	// Events
	$(".toggle-password").click(function(){
		counterToggle++;
		hidePassword(this, counterToggle);
		adjustTooltipText(this);
	});
	
});