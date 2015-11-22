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
          spanobj.append '<span class="label' + message.flags.tb_labels[idx] + '">&#8226;</span>'
      else
        # thunderbird UI style
        for idx of message.flags.tb_labels
          rowobj.addClass 'label' + message.flags.tb_labels[idx]
  return

rcm_tb_label_flag_toggle = (flag_uids, toggle_label_no, onoff) ->
  headers_table = $('table.headers-table')
  preview_frame = $('#messagecontframe')
  tb_labels_for_message = []
  # preview frame exists, simulate environment of single message view
  if preview_frame.length
    tb_labels_for_message = preview_frame.get(0).contentWindow.tb_labels_for_message
    headers_table = preview_frame.contents().find('table.headers-table')
  if !rcmail.message_list and !headers_table
    return
  # for single message view
  if headers_table.length and flag_uids.length
    if onoff == true
      if rcmail.env.tb_label_style == 'bullets'
        $('#labelbox').append '<span class="tb_label_span' + toggle_label_no + '">' + rcmail.env.tb_label_custom_labels[toggle_label_no] + '</span>'
      else
        headers_table.addClass 'label' + toggle_label_no
      # add to flag list
      tb_labels_for_message.push toggle_label_no
    else
      if rcmail.env.tb_label_style == 'bullets'
        $('span.tb_label_span' + toggle_label_no).remove()
      else
        headers_table.removeClass 'label' + toggle_label_no
      pos = jQuery.inArray(toggle_label_no, tb_labels_for_message)
      if pos > -1
        tb_labels_for_message.splice pos, 1
    # exit function when in detail mode. when preview is active keep going
    if !rcmail.env.messages
      return
  jQuery.each flag_uids, (idx, uid) ->
    message = rcmail.env.messages[uid]
    row = rcmail.message_list.rows[uid]
    if onoff == true
      # add colors
      rowobj = $(row.obj)
      spanobj = rowobj.find('td.subject span.tb_label_dots')
      if rcmail.env.tb_label_style == 'bullets'
        spanobj.append '<span class="label' + toggle_label_no + '">&#8226;</span>'
      else
        rowobj.addClass 'label' + toggle_label_no
      # add to flag list
      message.flags.tb_labels.push toggle_label_no
    else
      # remove colors
      rowobj = $(row.obj)
      if rcmail.env.tb_label_style == 'bullets'
        rowobj.find('td.subject span.tb_label_dots span.label' + toggle_label_no).remove()
      else
        rowobj.removeClass 'label' + toggle_label_no
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
      toggle_label = $(this).parent().attr('class')
      toggle_label_no = parseInt(toggle_label.replace('label', ''))
      selection = rcm_tb_label_get_selection()
      if !selection.length
        return
      from = toggle_label_no
      to = toggle_label_no + 1
      unset_all = false
      # special case flag 0 means remove all flags
      if toggle_label_no == 0
        from = 1
        to = 6
        unset_all = true
      i = from
      while i < to
        toggle_label = 'label' + i
        toggle_label_no = i
        # compile list of unflag and flag msgs and then send command
        # Thunderbird modifies multiple message flags like it did the first in the selection
        # e.g. first message has flag1, you click flag1, every message select loses flag1, the ones not having flag1 don't get it!
        first_toggle_mode = 'on'
        if rcmail.env.messages
          first_message = rcmail.env.messages[selection[0]]
          if first_message.flags and jQuery.inArray(toggle_label_no, first_message.flags.tb_labels) >= 0
            first_toggle_mode = 'off'
          else
            first_toggle_mode = 'on'
        else
          # flag already set?
          if jQuery.inArray(toggle_label_no, tb_labels_for_message) >= 0
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
