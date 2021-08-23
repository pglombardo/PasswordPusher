import 'spoiler-alert/spoiler'

import ClipboardJS from 'clipboard'

function setCookie(name,value,days) {
  var expires = "";
  if (days) {
      var date = new Date();
      date.setTime(date.getTime() + (days*24*60*60*1000));
      expires = "; expires=" + date.toUTCString();
  }
  document.cookie = name + "=" + (value || "")  + expires + "; path=/";
}

function getCookie(name) {
  var nameEQ = name + "=";
  var ca = document.cookie.split(';');

  for(var i=0;i < ca.length;i++) {
      var c = ca[i];
      while (c.charAt(0)==' ') c = c.substring(1,c.length);
      if (c.indexOf(nameEQ) == 0) return c.substring(nameEQ.length,c.length);
  }
  return null;
}

function restoreFormValuesFromCookie() {
  var days = getCookie('pwpush_days');
  var views = getCookie('pwpush_views');

  var de = document.getElementById("password_expire_after_days")
  var dr = document.getElementById("daysrange")
  if (de) {
    if (days) {
      de.value = days
      dr.innerText = days + " Days"
    } else {
      showDaysValue(de.value)
    }
  }

  var ve = document.getElementById("password_expire_after_views")
  var vr = document.getElementById("viewsrange")
  if (ve) {
    if (views) {
      ve.value = views
      vr.innerText = views + " Views"
    } else {
      showViewsValue(ve.value)
    }
  }

  var dbv_checkbox = document.getElementById('password_deletable_by_viewer')
  var dbv_check_state = getCookie('pwpush_dbv')
  if (dbv_checkbox) {
    var new_value = true;
    if (dbv_check_state) {
      if (dbv_check_state == "false") {
        new_value = false
      }
      if (dbv_checkbox.checked != new_value) {
        dbv_checkbox.click()
      }
    }
  }
  
  var retrieval_checkbox = document.getElementById('password_retrieval_step')
  var retrieval_check_state = getCookie('pwpush_retrieval')
  if (retrieval_checkbox) {
    var new_value = true;
    if (retrieval_check_state) {
      if (retrieval_check_state == "false") {
        new_value = false
      }
      if (retrieval_checkbox.checked != new_value) {
        retrieval_checkbox.click()
      }
    }
  }

}

function saveFormValuesToCookie() {
  var days_value  = document.getElementById("password_expire_after_days").value
  var views_value = document.getElementById("password_expire_after_views").value
  var dbv         = document.getElementById("password_deletable_by_viewer")
  var retrieval   = document.getElementById("password_retrieval_step")

  setCookie('pwpush_days',  days_value, 365);
  setCookie('pwpush_views', views_value, 365);
  setCookie('pwpush_dbv', dbv.checked.toString(), 365);
  setCookie('pwpush_retrieval', retrieval.checked.toString(), 365);

  let e = document.getElementById("cookie-save")
  e.innerHTML = "Saved!  <em>Defaults updated.</em>"
  return true;
}

function setupSliderEventListeners()
{
  var slider_days = document.getElementById('password_expire_after_days');
  var slider_views = document.getElementById('password_expire_after_views');

  if (slider_days) {
    slider_days.addEventListener("change", function() {
      document.getElementById("daysrange").innerText=slider_days.value + ' Days';
    })
    slider_days.addEventListener("input", function() {
      document.getElementById("daysrange").innerText=slider_days.value + ' Days';
    })
  }
  
  if (slider_views) {
    slider_views.addEventListener("change", function() {
      document.getElementById("viewsrange").innerText=slider_views.value + ' Days';
    })
    slider_views.addEventListener("input", function() {
      document.getElementById("viewsrange").innerText=slider_views.value + ' Days';
    })
  }
}

function ready() {
  restoreFormValuesFromCookie();

  var secret_url_clipboard = new ClipboardJS('#clipboard-secret-url');
  secret_url_clipboard.on('success', function(e) {
    var clipboardButton = document.getElementById("clipboard-secret-url");
    var copyIcon = clipboardButton.innerHTML;
    clipboardButton.innerText = "Copied!"
    setTimeout(function() {
          clipboardButton.innerHTML = copyIcon;
    }, 1000);
    e.clearSelection();
  });

  var pw_clipboard = new ClipboardJS('#clipboard-button');
  pw_clipboard.on('success', function(e) {
    var clipboardButton = document.getElementById("clipboard-button");
    clipboardButton.innerText = "Copied!"
    setTimeout(function() {
          clipboardButton.innerText = "Copy to Clipboard";
    }, 2000);
    e.clearSelection();
  });

  // "Save these settings as default in a cookie"
  document.getElementById("save-defaults").addEventListener('click', saveFormValuesToCookie);

  // Range sliders update their labels on change
  setupSliderEventListeners()

  // Password Payload character count
  document.getElementById('password_payload').addEventListener('change', updateCharCount);

  // Enable Payload Blur
  spoilerAlert('spoiler, .spoiler', {max: 10, partial: 4});
}

document.addEventListener("DOMContentLoaded", ready);

// $('#password_payload').keypress(function() {
//   if ($('#password_payload').val().length > 250) {
//     noty({text: 'Passwords can be up to 250 characters maximum in length.', type: 'warning'});
//     $.noty.clearQueue()
//     return false;
//   }
// });



function updateCharCount() {
    
  var characterCount = $(this).val().length,
      current = $('#current'),
      maximum = $('#maximum'),
      theCount = $('#the-count');
    
  current.text(characterCount);
 
  
  /*This isn't entirely necessary, just playin around*/
  if (characterCount < 70) {
    current.css('color', '#666');
  }
  if (characterCount > 70 && characterCount < 90) {
    current.css('color', '#6d5555');
  }
  if (characterCount > 90 && characterCount < 100) {
    current.css('color', '#793535');
  }
  if (characterCount > 100 && characterCount < 120) {
    current.css('color', '#841c1c');
  }
  if (characterCount > 120 && characterCount < 139) {
    current.css('color', '#8f0001');
  }
  
  if (characterCount >= 140) {
    maximum.css('color', '#8f0001');
    current.css('color', '#8f0001');
    theCount.css('font-weight','bold');
  } else {
    maximum.css('color','#666');
    theCount.css('font-weight','normal');
  }
  
}

function showDaysValue(newValue)
{
  if (newValue > 1) {
  	document.getElementById("daysrange").innerHTML=newValue + ' Days';
  } else {
  	document.getElementById("daysrange").innerHTML=newValue + ' Day';
  }
}

function showViewsValue(newValue)
{
  if (newValue > 1) {
  	document.getElementById("viewsrange").innerHTML=newValue + ' Views';
  } else {
  	document.getElementById("viewsrange").innerHTML=newValue + ' View';
  }
}

function setCopied() {
	$('#clip_tip').text('copied!');
}

