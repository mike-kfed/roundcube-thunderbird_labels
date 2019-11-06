# prototype for string formatting
String::format = (args...) ->
  @replace /{(\d+)}/g, (match, number) ->
    if number < args.length then args[number] else match

class rcm_tb_label_css

  constructor: ->
    @default_colors = {'bg': '#8CC', 'fg': '#880000', 'light': '#800', 'box': '#882200'}
    @label_colors = {
      'LABEL1': {'bg': '#FCC', 'fg': '#FF0000', 'light': '#f00', 'box': '#FF2200'},
      'LABEL2': {'bg': '#FC3', 'fg': '#FF9900', 'light': '#f90', 'box': '#FF9900'},
      'LABEL3': {'bg': '#3C3', 'fg': '#009900', 'light': '#090', 'box': '#00CC00'},
      'LABEL4': {'bg': '#99F', 'fg': '#3333FF', 'light': '#0CF', 'box': '#0CF'},
      'LABEL5': {'bg': '#C9C', 'fg': '#993399', 'light': '#B6F', 'box': '#FF33FF'},
    }

  generate: ->
    css = ''
    for label_name, colors of @label_colors
      # TODO escape label_name
      escaped_label_name = 'tb_label_' + label_name
      css += """
      table.{0}
      {
        background-color: {1};
      }
      """.format escaped_label_name, colors.bg

      # Unselected (unfocused) messages
      css += """
      #messagelist tr.{0} td,
      #messagelist tr.{0} td a,
      span.{0},
      .records-table tr.selected td span.{0}
      {
        color: {1} !important;
      }

      .toolbarmenu li.{0},
      .toolbarmenu li.{0} a.active
      {
        color: {2};
      }
      """.format escaped_label_name, colors.fg, colors.light

      # Selected messages
      css += """
      #messagelist tr.selected.{0} td,
      #messagelist tr.selected.{0} td a
      {
        color: #FFFFFF;
        background-color: {1};
      }
      """.format escaped_label_name, colors.bg

      css += """
      div#labelbox span.box_{0}
      {
        background-color: {1};
      }
      """.format escaped_label_name, colors.box
    return css

  inject: ->
    $("<style>")
    .prop("type", "text/css")
    .html(@generate())
    .appendTo("head");
