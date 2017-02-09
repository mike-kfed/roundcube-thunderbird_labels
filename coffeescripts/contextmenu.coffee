# thunderbird_labels integration for contextmenu plugin (with help from Philip Weir)
rcmail.addEventListener 'contextmenu_init', (menu) ->
  # dentify the folder list context menu
  console.log(menu.menu_name);
  if menu.menu_name == 'messagelist'
    menu.addEventListener 'init', (p) ->
      if p.ref.menu_name == 'tb_label_popup'
        # the thunderbird_labels popup menu is not a typical Roundcube popup
        # intercept the menu creation and build our own
        $(p.ref.container).children('ul').remove();
        labels = $('#tb_label_popup ul').clone();
        $(labels).find('a').click () ->
          # thunderbird_labels commands need message selection information
          # code to simulate message selection taken from contextmenu core
          if (p.ref.list_object)
            prev_display_next = rcmail.env.display_next;

            if (!(p.ref.list_object.selection.length == 1 && p.ref.list_object.in_selection(rcmail.env.context_menu_source_id)))
              rcmail.env.display_next = false

            prev_sel = p.ref.list_selection(true);
          # the thunderbird_labels command
          rcm_tb_label_onclick()
          if (p.ref.list_object)
            p.ref.list_selection(false, prev_sel)
            rcmail.env.display_next = prev_display_next
          undefined

      $(p.ref.container).append(labels)
      undefined

    menu.addEventListener 'activate', (p) ->
      # the thunderbird_labels commands do not match the pattern used in the Roundcube core so some custom handling is needed.
      # overwrite the default command activation function
      # setup a submenu and define the functions to show it
      if p.btn == 'tb'
        if (!$(p.el).parent('li').hasClass('submenu'))
          ref = rcmail.env.contextmenus['messagelist'];

          $(p.el).parent('li').addClass('submenu');
          $(p.el).append("<span class='right-arrow'></span>");
          $(p.el).data('command', 'tb_label_popup');

          $(p.el).unbind('click'); # remove the default contextmenu click event
          # code below taken from the contextmenu core for showing/hiding submenus
          $(p.el).click (e) ->
            if (!$(this).hasClass('active'))
              return;

            ref.submenu(this, e);
            return false;

          if (ref.mouseover_timeout > -1)
            $(p.el).mouseover (e) ->
              if (!$(this).hasClass('active'))
                return;

              ref.timers['submenu_show'] = window.setTimeout (a, e) ->
                  ref.submenu(a, e)
                  undefined
                , ref.mouseover_timeout, $(p.el), e

            $(p.el).mouseout (e) ->
              $(this).blur()
              clearTimeout(ref.timers['submenu_show'])
              undefined

        # contextmenu plugin automatically hide things that it does not think look like Roundcube commands
        # make sure the labels command is visible
        $(p.el).parent('li').show();

        # check if the command is enabled
        rcmail.commands['plugin.thunderbird_labels.rcm_tb_label_submenu']
  undefined
