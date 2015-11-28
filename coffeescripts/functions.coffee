# Shows the colors based on flag info like in Thunderbird
# (called when a new message in inserted in list of messages)
# maybe slow ? called for each message in mailbox at init
rcm_tb_label_insert = (uid, row) ->
  if typeof rcmail.env is 'undefined' or typeof rcmail.env.messages is 'undefined'
    return
  message = rcmail.env.messages[uid]
  rowobj = $(row.obj)
  # add span container for little colored bullets
  rowobj.find('td.subject').append '<span class="tb_label_dots"></span>'
  if message.flags and message.flags.tb_labels
    if message.flags.tb_labels.length
      spanobj = rowobj.find('td.subject span.tb_label_dots')
      message.flags.tb_labels.sort (a, b) ->
        a - b
      if rcmail.env.tb_label_style == 'bullets'
        # bullets UI style
        for idx of message.flags.tb_labels
          spanobj.append '<span class="tb_label_' + message.flags.tb_labels[idx] + '">&#8226;</span>'
      else
        # thunderbird UI style
        for idx of message.flags.tb_labels
          rowobj.addClass 'tb_label_' + message.flags.tb_labels[idx]
  return

# Problem: mail-preview-pane is an iframe, so referencing global variables does
# not work as intended. So here I try to find out where this javascript is run
# and when needed adjust the pointer to the main window object.
rcm_tb_label_find_main_window = ->
  ms = $('#mainscreen')
  preview_frame = $('#messagecontframe')
  popup_window = $('body.extwin')
  # i have a mainscreen and preview_frame
  # this means i run in the main window
  if ms.length and preview_frame.length
    w = window
  # if have no mainscreen and body has class iframe
  # this means i run in the iframe of the preview, better get my parent
  if not ms.length and not preview_frame.length
    # TODO check for $('body.iframe') might make it more reliable
    w = window.parent
  if popup_window.length
    # i run in a popup window (message to be shown in popup can be configured
    # by the user)
    # theoretically we should point at window.opener, but this is unreliable,
    # reload of the page in popup window makes the relation between parent+popup
    # potentially go away.
    # php injects the needed global variables into the popup window html code
    # Problem: changes of labels are not known to the main window.
    w = window
  ms = w.document.getElementById('mainscreen')
  if not ms
    console.log("mainscreen still not found")
    return null
  return w

rcm_tb_label_global = (var_name) ->
  return rcm_tb_label_find_main_window()[var_name]

rcm_tb_label_global_set = (var_name, value) ->
  rcm_tb_label_find_main_window()[var_name] = value


rcm_tb_label_flag_toggle = (flag_uids, toggle_label_no, onoff) ->
  if not flag_uids.length
    return
  console.log(flag_uids, toggle_label_no, onoff)
  preview_frame = $('#messagecontframe')
  labels_for_message = rcm_tb_label_global('tb_labels_for_message')

  # preview frame exists, try to find elements in preview iframe
  if preview_frame.length
    headers_table = preview_frame.contents().find('table.headers-table')
    label_box = preview_frame.contents().find('#labelbox')
  else
    headers_table = $('table.headers-table')
    label_box = $('#labelbox')
  if !rcmail.message_list and !headers_table.length
    return
  # for message preview, or single message view
  if headers_table.length
    if onoff == true
      if rcmail.env.tb_label_style == 'bullets'
        label_box.append '<span class="box_tb_label_' + toggle_label_no + '">' + rcmail.env.tb_label_custom_labels[toggle_label_no] + '</span>'
      else
        headers_table.addClass 'tb_label_' + toggle_label_no
      # add to flag list
      labels_for_message.push toggle_label_no
    else
      if rcmail.env.tb_label_style == 'bullets'
        label_box.find('span.box_tb_label_' + toggle_label_no).remove()
      else
        headers_table.removeClass 'tb_label_' + toggle_label_no
      pos = jQuery.inArray(toggle_label_no, labels_for_message)
      if pos > -1
        labels_for_message.splice pos, 1
    # make list unique
    labels_for_message = jQuery.grep(labels_for_message, (v, k) ->
      return jQuery.inArray(v, labels_for_message) is k
    )
    rcm_tb_label_global_set('tb_labels_for_message', labels_for_message)
    # write global variable
  # exit function when in detail mode. when preview is active keep going
  if !rcmail.env.messages
    return
  jQuery.each flag_uids, (idx, uid) ->
    message = rcmail.env.messages[uid]
    row = rcmail.message_list.rows[uid]
    if onoff == true
      # check if label is already set
      if jQuery.inArray(toggle_label_no, message.flags.tb_labels) > -1
        return
      # add colors
      rowobj = $(row.obj)
      spanobj = rowobj.find('td.subject span.tb_label_dots')
      if rcmail.env.tb_label_style == 'bullets'
        spanobj.append '<span class="tb_label_' + toggle_label_no + '">&#8226;</span>'
      else
        rowobj.addClass 'tb_label_' + toggle_label_no
      # add to flag list
      message.flags.tb_labels.push toggle_label_no
    else
      # remove colors
      rowobj = $(row.obj)
      if rcmail.env.tb_label_style == 'bullets'
        rowobj.find('td.subject span.tb_label_dots span.tb_label_' + toggle_label_no).remove()
      else
        rowobj.removeClass 'tb_label_' + toggle_label_no
      # remove from flag list
      pos = jQuery.inArray(toggle_label_no, message.flags.tb_labels)
      if pos > -1
        message.flags.tb_labels.splice pos, 1
    return
  return

rcm_tb_label_flag_msgs = (flag_uids, toggle_label_no) ->
  rcm_tb_label_flag_toggle flag_uids, toggle_label_no, true
  return

rcm_tb_label_unflag_msgs = (unflag_uids, toggle_label_no) ->
  rcm_tb_label_flag_toggle unflag_uids, toggle_label_no, false
  return

# helper function to get selected/active messages

rcm_tb_label_get_selection = ->
  selection = if rcmail.message_list then rcmail.message_list.get_selection() else []
  if selection.length == 0 and rcmail.env.uid
    selection = [ rcmail.env.uid ]
  selection

rcm_tb_label_init_onclick = ->
  i = 0
  while i < 6
    # find the "HTML a tags" of tb-label submenus
    cur_a = $('#tb_label_popup li.label' + i + ' a')
    # TODO check if click event is defined instead of unbinding?
    cur_a.unbind 'click'
    cur_a.click ->
      toggle_label = $(this).parent().data('labelname')
      toggle_label_no = toggle_label
      selection = rcm_tb_label_get_selection()
      if !selection.length
        return
      from = 1
      to = 2
      unset_all = false
      # special case flag 0 means remove all flags
      if toggle_label == 'LABEL0'
        from = 1
        to = 6
        unset_all = true
      i = from
      while i < to
        toggle_label = 'LABEL' + i
        toggle_label_no = toggle_label
        # compile list of unflag and flag msgs and then send command
        # Thunderbird modifies multiple message flags like it did the first in the selection
        # e.g. first message has flag1, you click flag1, every message select loses flag1,
        #      the ones not having flag1 don't get it!
        first_toggle_mode = 'on'
        if rcmail.env.messages
          first_message = rcmail.env.messages[selection[0]]
          if first_message.flags and jQuery.inArray(toggle_label_no, first_message.flags.tb_labels) >= 0
            first_toggle_mode = 'off'
          else
            first_toggle_mode = 'on'
        else
          # flag already set?
          if jQuery.inArray(toggle_label_no, rcm_tb_label_global('tb_labels_for_message')) >= 0
            first_toggle_mode = 'off'
        flag_uids = []
        unflag_uids = []
        jQuery.each selection, (idx, uid) ->
          # message list not available (example: in detailview)
          if !rcmail.env.messages
            if first_toggle_mode == 'on'
              flag_uids.push uid
            else
              unflag_uids.push uid
            # make sure for unset all there is the single message id
            if unset_all and unflag_uids.length == 0
              unflag_uids.push uid
            return
          message = rcmail.env.messages[uid]
          if message.flags and jQuery.inArray(toggle_label_no, message.flags.tb_labels) >= 0
            if first_toggle_mode == 'off'
              unflag_uids.push uid
          else
            if first_toggle_mode == 'on'
              flag_uids.push uid
          return
        if unset_all
          flag_uids = []
        # skip sending flags to backend that are not set anywhere
        if flag_uids.length == 0 and unflag_uids.length == 0
          i++
          continue
        str_flag_uids = flag_uids.join(',')
        str_unflag_uids = unflag_uids.join(',')
        lock = rcmail.set_busy(true, 'loading')
        # call PHP set_flags to set the flags in IMAP server
        rcmail.http_request 'plugin.thunderbird_labels.set_flags', '_flag_uids=' + str_flag_uids + '&_unflag_uids=' + str_unflag_uids + '&_mbox=' + urlencode(rcmail.env.mailbox) + '&_toggle_label=' + toggle_label, lock
        # remove/add classes and tb labels from messages in JS
        rcm_tb_label_flag_msgs flag_uids, toggle_label_no
        rcm_tb_label_unflag_msgs unflag_uids, toggle_label_no
        i++
      return
    i++
  return

rcmail_ctxm_label = (command, el, pos) ->
  # my code works only on selected rows, contextmenu also on unselected
  # so if no selection is available, use the uid set by contextmenu plugin
  selection = if rcmail.message_list then rcmail.message_list.get_selection() else []
  if !selection.length and !rcmail.env.uid
    return
  if !selection.length and rcmail.env.uid
    rcmail.message_list.select_row rcmail.env.uid
  cur_a = $('#tb_label_popup li.label' + rcmail.tb_label_no + ' a')
  if cur_a
    cur_a.click()
  return

rcmail_ctxm_label_set = (which) ->
  # hack for my contextmenu submenu hack to propagate the selected label-no
  rcmail.tb_label_no = which
  return
