function setHiddenTimeZone(form) {
	var localTime = new Date();
	var tz = localTime.getTimezoneOffset()/60 * (-1);
	var hidTz = document.createElement('input');
	hidTz.setAttribute("id", "hidTz");
	hidTz.setAttribute("name", "hidTz");
	hidTz.setAttribute("type", "hidden");
	hidTz.setAttribute("value", tz);
	$(form).appendChild(hidTz);
    return true;
}

function toggleDiv(divId) {
	var ele = $(divId)
    var style = "block";

    if (ele.style.display == "block") {
		style = "none";
    }

    ele.style.display = style;
}

function navigate(route, confirm_msg) {
	var f = document.getElementsByTagName('form').item(0);
	submit = true;

	if (confirm_msg.length > 0)	{
		submit = confirm(confirm_msg);
	}

	if (submit) {
		if (f) {
			f.action = route;
			f.submit();
		}
		else {
			document.location.href = route;
		}
	}
}

function autoRefreshOn() {
	window.setTimeout('location.reload(true)', 60000);
}

