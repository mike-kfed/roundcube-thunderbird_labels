# global variable for contextmenu actions
require ('../node_modules/roundcube')(rcmail)

rcmail_tb_label_menu = (p) ->
  if typeof rcmail_ui == 'undefined'
    window.rcmail_ui = UI
  # elastic skin of 1.4beta does not have show_popup
  if !rcmail_ui.show_popup
    # TODO: use aria-popup
    return
  if !rcmail_ui.check_tb_popup()
    rcmail_ui.tb_label_popup_add()
  # Show the popup menu with tags
  # -- skin larry vs classic
  if typeof rcmail_ui.show_popupmenu == 'undefined'
    rcmail_ui.show_popup 'tb_label_popup'
  else
    rcmail_ui.show_popupmenu 'tb_label_popup'
  false

# Shows the submenu of thunderbird labels
rcm_tb_label_submenu = (p) ->
  if typeof rcmail_ui == 'undefined'
    window.rcmail_ui = UI
  # elastic skin of 1.4beta does not have show_popup
  if !rcmail_ui.show_popup
    # TODO: use aria-popup
    return
  # setup onclick and active/non active classes
  rcm_tb_label_create_popupmenu()
  # -- create sensible popup, using roundcubes internals
  if !rcmail_ui.check_tb_popup()
    rcmail_ui.tb_label_popup_add()
  # -- skin larry vs classic
  if typeof rcmail_ui.show_popupmenu == 'undefined'
    rcmail_ui.show_popup 'tb_label_popup'
  else
    rcmail_ui.show_popupmenu 'tb_label_popup'
  false

rcm_tb_label_create_popupmenu = ->
  i = 0
  while i < 6
    cur_a = $('li.label' + i + ' a')
    # add/remove active class
    selection = rcm_tb_label_get_selection()
    if selection.length == 0
      cur_a.removeClass 'active'
    else
      cur_a.addClass 'active'
    i++
  return
