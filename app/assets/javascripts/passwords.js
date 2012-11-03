// # Place all the behaviors and hooks related to the matching controller here.
// # All this logic will automatically be available in application.js.
// # You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

function saveExpirations()
{
  days_value = document.getElementById("password_expire_after_days").value
  views_value = document.getElementById("password_expire_after_views").value
  
  $.cookie('pwpush_days',  days_value);
  $.cookie('pwpush_views', views_value);
  
  e = document.getElementById("cookie-save")
  e.innerHTML = "Saved!"
  return true;
}

$(document).ready(function() {
  days = $.cookie('pwpush_days');
  views = $.cookie('pwpush_views');
  
  if (days) {
    de = document.getElementById("password_expire_after_days")
    dr = document.getElementById("daysrange")
    de.value = days
    dr.innerHTML = days + " Days"
  }
  
  if (views) {
    ve = document.getElementById("password_expire_after_views")
    vr = document.getElementById("viewsrange")
    ve.value = views
    vr.innerHTML = views + " Views"
  }
});