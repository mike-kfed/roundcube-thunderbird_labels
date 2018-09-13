###
Version: 1.2.0
Author: Michael Kefeder
https://github.com/mike-kfed/roundcube-thunderbird_labels
###

require ('../node_modules/jquery')($, window)

# document.ready
$ ->
  rcm_tb_label_init_onclick()
  css = new rcm_tb_label_css
  css.inject()
  # superglobal variable set? if not set it
  if not rcm_tb_label_global('tb_labels_for_message')?
    rcm_tb_label_global_set('tb_labels_for_message', [])
  # add keyboard shortcuts for keyboard and keypad if pref tb_label_enable_shortcuts=true
  if rcmail.env.tb_label_enable_shortcuts
    $(document).keyup (e) ->
      #console.log('Handler for .keyup() called.' + e.which);
      k = e.which
      if k > 47 and k < 58 or k > 95 and k < 106
        label_no = k % 48
        cur_a = $('#tb_label_popup li.label' + label_no + ' a')
        if cur_a
          cur_a.click()
      return
  # if exists add contextmenu entries
  if window.rcm_contextmenu_register_command
    rcm_contextmenu_register_command 'ctxm_tb_label', rcmail_ctxm_label, $('#tb_label_ctxm_mainmenu'), 'moreacts', 'after', true
  # single message displayed?
  labels_for_message = tb_labels_for_message
  if labels_for_message
    labelbox_parent = $('div.message-headers')
    # larry skin
    if !labelbox_parent.length
      labelbox_parent = $('table.headers-table tbody tr:first-child')
      # classic skin
    labelbox_parent.append '<div id="labelbox"></div>'
    labels_for_message.sort (a, b) ->
      a - b
    jQuery.each labels_for_message, (idx, val) ->
      rcm_tb_label_flag_msgs [ -1 ], val
      return
    rcm_tb_label_global_set('tb_labels_for_message', labels_for_message)

  # This hook is triggered after a new row was added to the message list
  # or the contacts list respectively.
  rcmail.addEventListener 'insertrow', (event) ->
    rcm_tb_label_insert event.uid, event.row
    return

  # This is the place where plugins can add their UI elements and register custom commands.
  rcmail.addEventListener 'init', (evt) ->
    #rcmail.register_command('plugin.thunderbird_labels.rcm_tb_label_submenu', rcm_tb_label_submenu, true);
    rcmail.register_command 'plugin.thunderbird_labels.rcm_tb_label_submenu', rcm_tb_label_submenu, rcmail.env.uid
    rcmail.register_command 'plugin.thunderbird_labels.rcm_tb_label_onclick', rcm_tb_label_menuclick, rcmail.env.uid
    # add event-listener to message list
    if rcmail.message_list
      rcmail.message_list.addEventListener 'select', (list) ->
        rcmail.enable_command 'plugin.thunderbird_labels.rcm_tb_label_submenu', list.get_selection().length > 0
        rcmail.enable_command 'plugin.thunderbird_labels.rcm_tb_label_onclick', list.get_selection().length > 0
        return
    return

  # handle response after refresh (try to update flags set by another
  # email-client while being logged into roundcube)
  rcmail.addEventListener 'responsebeforerefresh', (p) ->
    # recent_flags env is set in php thunderbird_labels::check_recent_flags()
    if p.response.env.recent_flags?
      default_flags = ['SEEN', 'UNSEEN', 'ANSWERED', 'FLAGGED', 'DELETED', 'DRAFT', 'RECENT', 'NONJUNK', 'JUNK']
      $.each p.response.env.recent_flags, (uid, flags) ->
        message = rcmail.env.messages[uid]
        if typeof message.flags.tb_labels is 'object'
          unset_labels = message.flags.tb_labels
        else
          unset_labels = ['LABEL1', 'LABEL2', 'LABEL3', 'LABEL4', 'LABEL5']
        $.each flags, (flagname, flagvalue) ->
          flagname = flagname.toUpperCase()
          if flagvalue and jQuery.inArray(flagname, default_flags) == -1
            rcm_tb_label_flag_msgs [ uid ], flagname
            pos = jQuery.inArray(flagname, unset_labels)
            if pos > -1
              unset_labels.splice pos, 1
        $.each unset_labels, (idx, label_name) ->
          console.log("unset", uid, label_name)
          rcm_tb_label_unflag_msgs [ uid ], label_name
    return

  # -- add my submenu to roundcubes UI (for roundcube classic only?)
  if window.rcube_mail_ui
    rcube_mail_ui::tb_label_popup_add = ->
      add = "tb-label-menu": id: 'tb-label-menu'
      @popups = $.extend(@popups, add)
      obj = $('#' + @popups['tb-label-menu'].id)
      if obj.length
        @popups['tb-label-menu'].obj = obj
      else
        delete @popups['tb-label-menu']
      return

  if window.rcube_mail_ui
    rcube_mail_ui::check_tb_popup = ->
      # larry skin doesn't have that variable, popup works automagically, return true
      if typeof @popups == 'undefined'
        return true
      if @popups.tb_label_popup
        true
      else
        false
  return
