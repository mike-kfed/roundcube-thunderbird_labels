var rcm_tb_label_create_popupmenu, rcm_tb_label_find_main_window, rcm_tb_label_flag_msgs, rcm_tb_label_flag_toggle, rcm_tb_label_get_selection, rcm_tb_label_global, rcm_tb_label_global_set, rcm_tb_label_init_onclick, rcm_tb_label_insert, rcm_tb_label_submenu, rcm_tb_label_unflag_msgs, rcmail_ctxm_label, rcmail_ctxm_label_set, rcmail_tb_label_menu;

rcm_tb_label_insert = function(uid, row) {
  var idx, message, rowobj, spanobj;
  if (typeof rcmail.env === 'undefined' || typeof rcmail.env.messages === 'undefined') {
    return;
  }
  message = rcmail.env.messages[uid];
  rowobj = $(row.obj);
  rowobj.find('td.subject').append('<span class="tb_label_dots"></span>');
  if (message.flags && message.flags.tb_labels) {
    if (message.flags.tb_labels.length) {
      spanobj = rowobj.find('td.subject span.tb_label_dots');
      message.flags.tb_labels.sort(function(a, b) {
        return a - b;
      });
      if (rcmail.env.tb_label_style === 'bullets') {
        for (idx in message.flags.tb_labels) {
          spanobj.append('<span class="label' + message.flags.tb_labels[idx] + '">&#8226;</span>');
        }
      } else {
        for (idx in message.flags.tb_labels) {
          rowobj.addClass('label' + message.flags.tb_labels[idx]);
        }
      }
    }
  }
};

rcm_tb_label_find_main_window = function() {
  var ms, popup_window, preview_frame, w;
  ms = $('#mainscreen');
  preview_frame = $('#messagecontframe');
  popup_window = $('body.extwin');
  if (ms.length && preview_frame.length) {
    w = window;
  }
  if (!ms.length && !preview_frame.length) {
    w = window.parent;
  }
  if (popup_window.length) {
    w = window;
  }
  ms = w.document.getElementById('mainscreen');
  if (!ms) {
    console.log("mainscreen still not found");
    return null;
  }
  return w;
};

rcm_tb_label_global = function(var_name) {
  return rcm_tb_label_find_main_window()[var_name];
};

rcm_tb_label_global_set = function(var_name, value) {
  return rcm_tb_label_find_main_window()[var_name] = value;
};

rcm_tb_label_flag_toggle = function(flag_uids, toggle_label_no, onoff) {
  var headers_table, label_box, labels_for_message, pos, preview_frame;
  if (!flag_uids.length) {
    return;
  }
  preview_frame = $('#messagecontframe');
  labels_for_message = rcm_tb_label_global('tb_labels_for_message');
  if (preview_frame.length) {
    headers_table = preview_frame.contents().find('table.headers-table');
    label_box = preview_frame.contents().find('#labelbox');
  } else {
    headers_table = $('table.headers-table');
    label_box = $('#labelbox');
  }
  if (!rcmail.message_list && !headers_table.length) {
    console.log("no message_list no headers_table");
    return;
  }
  if (headers_table.length) {
    if (onoff === true) {
      if (rcmail.env.tb_label_style === 'bullets') {
        label_box.append('<span class="tb_label_span' + toggle_label_no + '">' + rcmail.env.tb_label_custom_labels[toggle_label_no] + '</span>');
      } else {
        headers_table.addClass('label' + toggle_label_no);
      }
      labels_for_message.push(toggle_label_no);
    } else {
      if (rcmail.env.tb_label_style === 'bullets') {
        label_box.find('span.tb_label_span' + toggle_label_no).remove();
      } else {
        headers_table.removeClass('label' + toggle_label_no);
      }
      pos = jQuery.inArray(toggle_label_no, labels_for_message);
      if (pos > -1) {
        labels_for_message.splice(pos, 1);
      }
    }
    labels_for_message = jQuery.grep(labels_for_message, function(v, k) {
      return jQuery.inArray(v, labels_for_message) === k;
    });
    console.log('flags after', labels_for_message);
    rcm_tb_label_global_set('tb_labels_for_message', labels_for_message);
  }
  if (!rcmail.env.messages) {
    return;
  }
  jQuery.each(flag_uids, function(idx, uid) {
    var message, row, rowobj, spanobj;
    message = rcmail.env.messages[uid];
    row = rcmail.message_list.rows[uid];
    if (onoff === true) {
      rowobj = $(row.obj);
      spanobj = rowobj.find('td.subject span.tb_label_dots');
      if (rcmail.env.tb_label_style === 'bullets') {
        spanobj.append('<span class="label' + toggle_label_no + '">&#8226;</span>');
      } else {
        rowobj.addClass('label' + toggle_label_no);
      }
      message.flags.tb_labels.push(toggle_label_no);
    } else {
      rowobj = $(row.obj);
      if (rcmail.env.tb_label_style === 'bullets') {
        rowobj.find('td.subject span.tb_label_dots span.label' + toggle_label_no).remove();
      } else {
        rowobj.removeClass('label' + toggle_label_no);
      }
      pos = jQuery.inArray(toggle_label_no, message.flags.tb_labels);
      if (pos > -1) {
        message.flags.tb_labels.splice(pos, 1);
      }
    }
  });
};

rcm_tb_label_flag_msgs = function(flag_uids, toggle_label_no) {
  rcm_tb_label_flag_toggle(flag_uids, toggle_label_no, true);
};

rcm_tb_label_unflag_msgs = function(unflag_uids, toggle_label_no) {
  rcm_tb_label_flag_toggle(unflag_uids, toggle_label_no, false);
};

rcm_tb_label_get_selection = function() {
  var selection;
  selection = rcmail.message_list ? rcmail.message_list.get_selection() : [];
  if (selection.length === 0 && rcmail.env.uid) {
    selection = [rcmail.env.uid];
  }
  return selection;
};

rcm_tb_label_init_onclick = function() {
  var cur_a, i;
  i = 0;
  while (i < 6) {
    cur_a = $('#tb_label_popup li.label' + i + ' a');
    cur_a.unbind('click');
    cur_a.click(function() {
      var first_message, first_toggle_mode, flag_uids, from, lock, selection, str_flag_uids, str_unflag_uids, to, toggle_label, toggle_label_no, unflag_uids, unset_all;
      toggle_label = $(this).parent().attr('class');
      toggle_label_no = parseInt(toggle_label.replace('label', ''));
      selection = rcm_tb_label_get_selection();
      if (!selection.length) {
        return;
      }
      from = toggle_label_no;
      to = toggle_label_no + 1;
      unset_all = false;
      if (toggle_label_no === 0) {
        from = 1;
        to = 6;
        unset_all = true;
      }
      i = from;
      while (i < to) {
        toggle_label = 'label' + i;
        toggle_label_no = i;
        first_toggle_mode = 'on';
        if (rcmail.env.messages) {
          first_message = rcmail.env.messages[selection[0]];
          if (first_message.flags && jQuery.inArray(toggle_label_no, first_message.flags.tb_labels) >= 0) {
            first_toggle_mode = 'off';
          } else {
            first_toggle_mode = 'on';
          }
        } else {
          if (jQuery.inArray(toggle_label_no, rcm_tb_label_global('tb_labels_for_message')) >= 0) {
            first_toggle_mode = 'off';
          }
        }
        flag_uids = [];
        unflag_uids = [];
        jQuery.each(selection, function(idx, uid) {
          var message;
          if (!rcmail.env.messages) {
            if (first_toggle_mode === 'on') {
              flag_uids.push(uid);
            } else {
              unflag_uids.push(uid);
            }
            if (unset_all && unflag_uids.length === 0) {
              unflag_uids.push(uid);
            }
            return;
          }
          message = rcmail.env.messages[uid];
          if (message.flags && jQuery.inArray(toggle_label_no, message.flags.tb_labels) >= 0) {
            if (first_toggle_mode === 'off') {
              unflag_uids.push(uid);
            }
          } else {
            if (first_toggle_mode === 'on') {
              flag_uids.push(uid);
            }
          }
        });
        if (unset_all) {
          flag_uids = [];
        }
        if (flag_uids.length === 0 && unflag_uids.length === 0) {
          i++;
          continue;
        }
        str_flag_uids = flag_uids.join(',');
        str_unflag_uids = unflag_uids.join(',');
        lock = rcmail.set_busy(true, 'loading');
        rcmail.http_request('plugin.thunderbird_labels.set_flags', '_flag_uids=' + str_flag_uids + '&_unflag_uids=' + str_unflag_uids + '&_mbox=' + urlencode(rcmail.env.mailbox) + '&_toggle_label=' + toggle_label, lock);
        rcm_tb_label_flag_msgs(flag_uids, toggle_label_no);
        rcm_tb_label_unflag_msgs(unflag_uids, toggle_label_no);
        i++;
      }
    });
    i++;
  }
};

rcmail_ctxm_label = function(command, el, pos) {
  var cur_a, selection;
  selection = rcmail.message_list ? rcmail.message_list.get_selection() : [];
  if (!selection.length && !rcmail.env.uid) {
    return;
  }
  if (!selection.length && rcmail.env.uid) {
    rcmail.message_list.select_row(rcmail.env.uid);
  }
  cur_a = $('#tb_label_popup li.label' + rcmail.tb_label_no + ' a');
  if (cur_a) {
    cur_a.click();
  }
};

rcmail_ctxm_label_set = function(which) {
  rcmail.tb_label_no = which;
};


/*
Version: 1.2.0
Author: Michael Kefeder
https:#github.com/mike-kfed/rcmail-thunderbird-labels
 */


$(function() {
  var labelbox_parent, labels_for_message;
  rcm_tb_label_init_onclick();
  if (rcm_tb_label_global('tb_labels_for_message') == null) {
    rcm_tb_label_global_set('tb_labels_for_message', []);
  }
  if (rcmail.env.tb_label_enable_shortcuts) {
    $(document).keyup(function(e) {
      var cur_a, k, label_no;
      k = e.which;
      if (k > 47 && k < 58 || k > 95 && k < 106) {
        label_no = k % 48;
        cur_a = $('#tb_label_popup li.label' + label_no + ' a');
        if (cur_a) {
          cur_a.click();
        }
      }
    });
  }
  if (window.rcm_contextmenu_register_command) {
    rcm_contextmenu_register_command('ctxm_tb_label', rcmail_ctxm_label, $('#tb_label_ctxm_mainmenu'), 'moreacts', 'after', true);
  }
  labels_for_message = rcm_tb_label_global('tb_labels_for_message');
  if (labels_for_message) {
    labelbox_parent = $('div.message-headers');
    if (!labelbox_parent.length) {
      labelbox_parent = $('table.headers-table tbody tr:first-child');
    }
    labelbox_parent.append('<div id="labelbox"></div>');
    labels_for_message.sort(function(a, b) {
      return a - b;
    });
    jQuery.each(labels_for_message, function(idx, val) {
      rcm_tb_label_flag_msgs([-1], val);
    });
    rcm_tb_label_global_set('tb_labels_for_message', labels_for_message);
  }
  rcmail.addEventListener('insertrow', function(event) {
    rcm_tb_label_insert(event.uid, event.row);
  });
  rcmail.addEventListener('init', function(evt) {
    rcmail.register_command('plugin.thunderbird_labels.rcm_tb_label_submenu', rcm_tb_label_submenu, rcmail.env.uid);
    if (rcmail.message_list) {
      rcmail.message_list.addEventListener('select', function(list) {
        rcmail.enable_command('plugin.thunderbird_labels.rcm_tb_label_submenu', list.get_selection().length > 0);
      });
    }
  });
  rcmail.addEventListener('responsebeforerefresh', function(p) {
    if (p.response.env.recent_flags != null) {
      $.each(p.response.env.recent_flags, function(uid, flags) {
        var unset_labels;
        unset_labels = [1, 2, 3, 4, 5];
        $.each(flags, function(flagname, flagvalue) {
          var label_no, pos;
          if (flagvalue && flagname.indexOf('label') === 0) {
            label_no = parseInt(flagname.replace('label', ''));
            rcm_tb_label_flag_msgs([uid], label_no);
            pos = jQuery.inArray(label_no, unset_labels);
            if (pos > -1) {
              return unset_labels.splice(pos, 1);
            }
          }
        });
        return $.each(unset_labels, function(idx, label_no) {
          console.log("unset", uid, label_no);
          return rcm_tb_label_unflag_msgs([uid], label_no);
        });
      });
    }
  });
  if (window.rcube_mail_ui) {
    rcube_mail_ui.prototype.tb_label_popup_add = function() {
      var add, obj;
      add = {
        tb_label_popup: {
          id: 'tb_label_popup'
        }
      };
      this.popups = $.extend(this.popups, add);
      obj = $('#' + this.popups.tb_label_popup.id);
      if (obj.length) {
        this.popups.tb_label_popup.obj = obj;
      } else {
        delete this.popups.tb_label_popup;
      }
    };
  }
  if (window.rcube_mail_ui) {
    rcube_mail_ui.prototype.check_tb_popup = function() {
      if (typeof this.popups === 'undefined') {
        return true;
      }
      if (this.popups.tb_label_popup) {
        return true;
      } else {
        return false;
      }
    };
  }
});


rcmail_tb_label_menu = function(p) {
  var rcmail_ui;
  if (typeof rcmail_ui === 'undefined') {
    rcmail_ui = UI;
  }
  if (!rcmail_ui.check_tb_popup()) {
    rcmail_ui.tb_label_popup_add();
  }
  if (typeof rcmail_ui.show_popupmenu === 'undefined') {
    rcmail_ui.show_popup('tb_label_popup');
  } else {
    rcmail_ui.show_popupmenu('tb_label_popup');
  }
  return false;
};

rcm_tb_label_submenu = function(p) {
  var rcmail_ui;
  if (typeof rcmail_ui === 'undefined') {
    rcmail_ui = UI;
  }
  rcm_tb_label_create_popupmenu();
  if (!rcmail_ui.check_tb_popup()) {
    rcmail_ui.tb_label_popup_add();
  }
  if (typeof rcmail_ui.show_popupmenu === 'undefined') {
    rcmail_ui.show_popup('tb_label_popup');
  } else {
    rcmail_ui.show_popupmenu('tb_label_popup');
  }
  return false;
};

rcm_tb_label_create_popupmenu = function() {
  var cur_a, i, selection;
  i = 0;
  while (i < 6) {
    cur_a = $('li.label' + i + ' a');
    selection = rcm_tb_label_get_selection();
    if (selection.length === 0) {
      cur_a.removeClass('active');
    } else {
      cur_a.addClass('active');
    }
    i++;
  }
};
