/**
* Author:
* Michael Kefeder
* http://code.google.com/p/rcmail-thunderbird-labels/
*/

// -- add my submenu to roundcubes UI
rcube_mail_ui.prototype.tb_label_menu = function() {
  add = {
    tb_label_menu:     {id:'tb_label_popup'}
  };
  this.popups = $.extend(this.popups, add);
  var obj = $('#'+this.popups.tb_label_menu.id);
  if (obj.length)
    this.popups.tb_label_menu.obj = obj;
  else {
    delete this.popups.tb_label_menu;
  }
}

function rcmail_tb_label_menu(p)
{
	if (!rcmail_ui.popups.tb_label_menu)
		rcmail_ui.tb_label_menu();
	
	// Show the popup menu with tags
	rcmail_ui.show_popupmenu('tb_label_popup');

	return false;
}

/**
* Shows the colors based on flag info like in Thunderbird
*/
function rcm_tb_label_insert(uid, row)
{
	var message = rcmail.env.messages[uid];
	
	if (message.flags && message.flags.tb_labels)
	{
		var rowobj = $(row.obj);
		for (idx in message.flags.tb_labels)
			rowobj.addClass('label' + message.flags.tb_labels[idx]);
	}
}

/**
* Shows the submenu of thunderbird labels
*/
function rcm_tb_label_submenu(p)
{
	// setup onclick and active/non active classes
	rcm_tb_label_create_popupmenu();
	// -- position the popup first, else it shows in weird places??
	var tb_label_popup = $('#tb_label_popup');
	
	tb_label_popup.css('left', $(p).offset().left);
	tb_label_popup.css('top', $(p).offset().top + 32);
	
	// -- create sensible popup, using roundcubes internals
	if (!rcmail_ui.popups.tb_label_menu)
		rcmail_ui.tb_label_menu();
	rcmail_ui.show_popupmenu('tb_label_menu');
	return false;
}

function rcm_tb_label_flag_msgs(flag_uids, toggle_label_no)
{
	jQuery.each(flag_uids, function (idx, uid) {
			var message = rcmail.env.messages[uid];
			var row = rcmail.message_list.rows[uid];
			// add colors
			var rowobj = $(row.obj);
			rowobj.addClass('label'+toggle_label_no);
			// add to flag list
			message.flags.tb_labels.push(toggle_label_no)
	});
}

function rcm_tb_label_unflag_msgs(unflag_uids, toggle_label_no)
{
	jQuery.each(unflag_uids, function (idx, uid) {
			var message = rcmail.env.messages[uid];
			var row = rcmail.message_list.rows[uid];
			// remove colors
			var rowobj = $(row.obj);
			rowobj.removeClass('label'+toggle_label_no);
			// remove from flag list
			var pos = jQuery.inArray(toggle_label_no, message.flags.tb_labels);
			if (pos > -1)
				message.flags.tb_labels.splice(pos, 1);
	});
}

function rcm_tb_label_create_popupmenu()
{
	for (i = 0; i < 6; i++)
	{
		var cur_a = $('li.label' + i +' a');
		
		// add/remove active class
		var selection = rcmail.message_list ? rcmail.message_list.get_selection() : [];
		if (selection.length == 0)
			cur_a.removeClass('active');
		else
			cur_a.addClass('active');
		
		// TODO check if click event is defined instead of unbinding?
		cur_a.unbind('click');
		cur_a.click(function() {
				var toggle_label = $(this).parent().attr('class');
				var toggle_label_no = parseInt(toggle_label.replace('label', ''));
				var selection = rcmail.message_list ? rcmail.message_list.get_selection() : [];
				
				if (!selection.length)
					return;
				
				var from = toggle_label_no;
				var to = toggle_label_no + 1;
				var unset_all = false;
				// special case flag 0 means remove all flags
				if (toggle_label_no == 0)
				{
					from = 1;
					to = 6;
					unset_all = true;
				}
				for (i = from; i < to; i++)
				{
					toggle_label = 'label' + i;
					toggle_label_no = i;
					// compile list of unflag and flag msgs and then send command
					var flag_uids = [];
					var unflag_uids = [];
					jQuery.each(selection, function (idx, uid) {
							var message = rcmail.env.messages[uid];
							if (message.flags
								&& jQuery.inArray(toggle_label_no,
										message.flags.tb_labels) >= 0
								)
								unflag_uids.push(uid);
							else
								flag_uids.push(uid);
					});
					
					if (unset_all)
						flag_uids = [];
					
					// skip sending flags to backend that are not set anywhere
					if (flag_uids.length == 0
						&& unflag_uids.length == 0)
							continue;
					
					var str_flag_uids = flag_uids.join(',');
					var str_unflag_uids = unflag_uids.join(',');
					
					var lock = rcmail.set_busy(true, 'loading');
					rcmail.http_request('plugin.thunderbird_labels.set_flags', '_flag_uids=' + str_flag_uids + '&_unflag_uids=' + str_unflag_uids + '&_mbox=' + urlencode(rcmail.env.mailbox) + "&_toggle_label=" + toggle_label, lock);
					
					// remove/add classes and tb labels from messages in JS
					rcm_tb_label_flag_msgs(flag_uids, toggle_label_no);
					rcm_tb_label_unflag_msgs(unflag_uids, toggle_label_no);
				}
		});
	}
}

$(document).ready(function() {
	rcmail.addEventListener('insertrow', function(event) { rcm_tb_label_insert(event.uid, event.row); });
	
	rcmail.addEventListener('init', function(evt) {
		// create custom button
		var button = $('<A>').attr('href', '#').attr('id', 'rcmTBLabelBtn').attr('title', rcmail.gettext('label', 'thunderbird_labels')).html('');
		
		button.bind('click', function(e) {
			rcmail.command('plugin.thunderbird_labels.rcm_tb_label_submenu', this);
			return false;
		});
		
		// add and register
		rcmail.add_element(button, 'toolbar');
		rcmail.register_button('plugin.thunderbird_labels.rcm_tb_label_submenu', 'rcmTBLabelBtn', 'link');
		rcmail.register_command('plugin.thunderbird_labels.rcm_tb_label_submenu', rcm_tb_label_submenu, true);
	});
});

