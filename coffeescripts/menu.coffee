# Shows the submenu of thunderbird labels
rcm_tb_label_submenu = (p, obj, ev) ->
  if typeof rcmail_ui == 'undefined'
    window.rcmail_ui = UI
  # elastic skin of 1.4beta does not have show_popup
  if !rcmail_ui.show_popup
    return
  # -- create sensible popup, using roundcubes internals
  if !rcmail_ui.check_tb_popup()
    rcmail_ui.tb_label_popup_add()
  # -- skin larry vs classic
  if typeof rcmail_ui.show_popupmenu == 'undefined'
    return  # behaves weird, disabled
    #rcmail_ui.show_popup 'tb-label-menu', ev  # larry
  else
    rcmail_ui.show_popupmenu 'tb-label-menu', ev  # classic
  false
