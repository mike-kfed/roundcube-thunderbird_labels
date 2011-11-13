/**
* Author:
* Michael Kefeder
* http://code.google.com/p/rcmail-thunderbird-labels/
*/

// global variable for contextmenu actions
rcmail.tb_label_no = '';

function rcmail_tb_label_menu(p)
{
	if (!rcmail_ui.popups.tb_label_popup)
		rcmail_ui.tb_label_popup_add();
	
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
	
	// -- create sensible popup, using roundcubes internals
	if (!rcmail_ui.popups.tb_label_popup)
		rcmail_ui.tb_label_popup_add();
	rcmail_ui.show_popupmenu('tb_label_popup');
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
	}
}

function rcm_tb_label_init_onclick()
{
	for (i = 0; i < 6; i++)
	{
		var cur_a = $('#tb_label_popup li.label' + i +' a');
	
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
					// Thunderbird modifies multiple message flags like it did the first in the selection
					// e.g. first message has flag1, you click flag1, every message select loses flag1, the ones not having flag1 don't get it!
					var first_toggle_mode = '';
					var first_message = rcmail.env.messages[selection[0]];
					if (first_message.flags
						&& jQuery.inArray(toggle_label_no,
								first_message.flags.tb_labels) >= 0
						)
						first_toggle_mode = 'off';
					else
						first_toggle_mode = 'on';
					
					var flag_uids = [];
					var unflag_uids = [];
					jQuery.each(selection, function (idx, uid) {
							var message = rcmail.env.messages[uid];
							if (message.flags
								&& jQuery.inArray(toggle_label_no,
										message.flags.tb_labels) >= 0
								)
							{
								if (first_toggle_mode == 'off')
									unflag_uids.push(uid);
							}
							else
							{
								if (first_toggle_mode == 'on')
									flag_uids.push(uid);
							}
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

function rcmail_ctxm_label(command, el, pos)
{
	// my code works only on selected rows, contextmenu also on unselected
	// so if no selection is available, use the uid set by contextmenu plugin
	var selection = rcmail.message_list ? rcmail.message_list.get_selection() : [];
	
	if (!selection.length && !rcmail.env.uid)
		return;
	if (!selection.length && rcmail.env.uid)
		rcmail.message_list.select_row(rcmail.env.uid);
	
	var cur_a = $('#tb_label_popup li.label' + rcmail.tb_label_no +' a');
	if (cur_a)
	{
		cur_a.click();
	}
	
	return;
}

function rcmail_ctxm_label_set(which)
{
	// hack for my contextmenu submenu hack to propagate the selected label-no
	rcmail.tb_label_no = which;
}


$(document).ready(function() {
	rcm_tb_label_init_onclick();
	// add keyboard shortcuts
	$(document).keyup(function(e) {
		//console.log('Handler for .keyup() called.' + e.which);
		var label_no = e.which - 48;
		var cur_a = $('#tb_label_popup li.label' + label_no +' a');
		
		if (cur_a)
		{
			cur_a.click();
		}
	});
	
	// if exists add contextmenu entries
	if (window.rcm_contextmenu_register_command) {
		rcm_contextmenu_register_command('ctxm_tb_label', rcmail_ctxm_label, $('#tb_label_ctxm_mainmenu'), 'moreacts', 'after', true);
	}
	
	// add roundcube events
	rcmail.addEventListener('insertrow', function(event) { rcm_tb_label_insert(event.uid, event.row); });
	
	rcmail.addEventListener('init', function(evt) {
		// create custom button
		var button = $('<A>').attr('href', '#').attr('id', 'tb_label_popuplink').attr('title', rcmail.gettext('label', 'thunderbird_labels')).html('');
		
		button.bind('click', function(e) {
			rcmail.command('plugin.thunderbird_labels.rcm_tb_label_submenu', this);
			return false;
		});
		
		// add and register
		rcmail.add_element(button, 'toolbar');
		rcmail.register_button('plugin.thunderbird_labels.rcm_tb_label_submenu', 'tb_label_popuplink', 'link');
		rcmail.register_command('plugin.thunderbird_labels.rcm_tb_label_submenu', rcm_tb_label_submenu, true);
	});
	
	// -- add my submenu to roundcubes UI
	rcube_mail_ui.prototype.tb_label_popup_add = function() {
/*console.log("tb_label_popup_add");
		if (this.popups.tb_label_popup)
			return;
*/		add = {
			tb_label_popup:     {id:'tb_label_popup'}
		};
		this.popups = $.extend(this.popups, add);
		var obj = $('#'+this.popups.tb_label_popup.id);
		if (obj.length)
			this.popups.tb_label_popup.obj = obj;
		else
			delete this.popups.tb_label_popup;
	};
});

