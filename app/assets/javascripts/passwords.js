// # Place all the behaviors and hooks related to the matching controller here.
// # All this logic will automatically be available in application.js.
// # You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

function saveExpirations()
{
  days_value  = document.getElementById("password_expire_after_time").value
  views_value = document.getElementById("password_expire_after_views").value
  dbv         = document.getElementById("password_deletable_by_viewer")

  Cookies.set('pwpush_days',  days_value, { expires: 365 });
  Cookies.set('pwpush_views', views_value, { expires: 365 });
  Cookies.set('pwpush_dbv', dbv.checked.toString(), { expires: 365 });

  e = document.getElementById("cookie-save")
  e.innerHTML = "Saved!"
  return true;
}

$(document).ready(function() {
  var clipboard = new Clipboard('.btn');
  clipboard.on('success', function(e) {
    alert("Copied to clipboard!");
    e.clearSelection();
  });

  days = Cookies.get('pwpush_days');
  views = Cookies.get('pwpush_views');

  de = document.getElementById("password_expire_after_time")
  dr = document.getElementById("daysrange")
  if (days) {
    de.value = days
    showDaysValue(de.value)
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

  dbv_checkbox = document.getElementById('password_deletable_by_viewer')
  dbv_check_state = Cookies.get('pwpush_dbv')
  if (dbv_check_state) {
    if (dbv_check_state == "false") {
      dbv = false
    } else {
      dbv = true
    }
    if (dbv_checkbox.checked != dbv) {
      dbv_checkbox.click()
    }
  }
});

$('#password_payload').keypress(function() {
  if ($('#password_payload').val().length > 250) {
    noty({text: 'Passwords can be up to 250 characters maximum in length.', type: 'warning'});
    $.noty.clearQueue()
    return false;
  }
});
var save_Placeholder=document.getElementById("password_payload").placeholder;
var visible = false;
//CSP Fix
document.getElementById("password_payload").addEventListener("click",function(){
  this.placeholder="";
});

document.getElementById("password_payload").addEventListener("blur",function(){
  this.placeholder=save_Placeholder;
});

document.getElementById("password_expire_after_time").addEventListener("change",function(){
  showDaysValue(this.value);
});

document.getElementById("password_expire_after_views").addEventListener("change",function(){
  showViewsValue(this.value);
});

document.getElementById("specialA").addEventListener("click",saveExpirations);

document.getElementById("visibleButton").addEventListener("click",function(){
  if (!visible) {
    visible = true;
    this.style.opacity="0.3";
    document.getElementById("password_payload").type="text"
  } else {
    visible = false;
    this.style.opacity="1.0";
    document.getElementById("password_payload").type="password"
  }
});