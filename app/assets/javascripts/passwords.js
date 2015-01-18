// # Place all the behaviors and hooks related to the matching controller here.
// # All this logic will automatically be available in application.js.
// # You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

function saveExpirations()
{
  days_value = document.getElementById("password_expire_after_days").value
  views_value = document.getElementById("password_expire_after_views").value

  $.cookie('pwpush_days',  days_value, { expires: 365 });
  $.cookie('pwpush_views', views_value, { expires: 365 });

  e = document.getElementById("cookie-save")
  e.innerHTML = "Saved!"
  return true;
}

$(document).ready(function() {
  days = $.cookie('pwpush_days');
  views = $.cookie('pwpush_views');

  de = document.getElementById("password_expire_after_days")
  dr = document.getElementById("daysrange")
  if (de && dr) {
    if (days) {
      de.value = days
      dr.innerHTML = days + " Days"
    } else {
      showDaysValue(de.value)
    }
  }
 
  ve = document.getElementById("password_expire_after_views")
  vr = document.getElementById("viewsrange")
  if (ve && vr) {
    if (views) {
      ve.value = views
      vr.innerHTML = views + " Views"
    } else {
      showViewsValue(ve.value)
    }
  }

  if ($('.payload.spoiler').length == 1) {
	var crypttext = $('.payload.spoiler').text();
	var pass64 = $.jStorage.get('pass64');
	if (pass64 === null) {
		pass64 = window.location.hash.substr(1);
	}
	window.location.hash = pass64;
	if ($('#share_url') && $('#clip_data')) {
		$('#share_url') .val(window.location);
		$('#clip_data').text(window.location);
	}
	var passBits = sjcl.codec.base64.toBits(pass64);
	$.jStorage.deleteKey('pass64');
	var cleartext = sjcl.decrypt(passBits, crypttext);
	$('.payload.spoiler').text(cleartext);
  }
});

$('#password_payload').keypress(function() {
  if ($('#password_payload').val().length > 250) {
    noty({text: 'Passwords can be up to 250 characters maximum in length.', type: 'warning'});
    $.noty.clearQueue()
    return false;
  }
});

$('form#new_password').submit(function() {
	var cleartext = $('#password_payload').val();

	if (cleartext) {
		var passBits = sjcl.random.randomWords(4); /* 4 words = 4*4*8 = 128 bits = AES key size */
		var pass64 = sjcl.codec.base64.fromBits(passBits);
		$.jStorage.set('pass64', pass64, {ttl: 3000});
		$('#password_payload').val(sjcl.encrypt(passBits, cleartext));
	}
});
