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
  if (days) {
    de.value = days
    dr.innerHTML = days + " Days"
  } else {
    showDaysValue(de.value)
  }

  ve = document.getElementById("password_expire_after_views")
  vr = document.getElementById("viewsrange")
  if (views) {
    ve.value = views
    vr.innerHTML = views + " Views"
  } else {
    showViewsValue(ve.value)
  }
});

$('#password_payload').keypress(function() {
  if ($('#password_payload').val().length > 250) {
    noty({text: 'Passwords can be up to 250 characters maximum in length.', type: 'warning'});
    $.noty.clearQueue()
    return false;
  }
});
