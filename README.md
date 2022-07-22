## Thunderbird Labels Plugin for Roundcube Webmail

### Features

* Displays the message rows using the same colors as Thunderbird does
* Label of a message can be changed/set exactly like in Thunderbird
* Keyboard shortcuts on keys 0-5 work like in Thunderbird
* Integrates into contextmenu plugin when available
* Works for skins *classic*, *larry* and *elastic*
* currently available translations:
  * English
  * French (Français)
  * German (Deutsch)
  * Polish (Polski)
  * Russian (Русский)
  * Hungarian (Magyar)
  * Czech (Česky)
  * Bulgarian (български език)
  * Catalan (català)
  * Latvian (latviešu)
  * Italian (italiano)
  * Spanish (español)
  * Slovak (Slovenčina)
  * Ukranian (українська)
  * Brazilian Portuguese (português do Brasil)
  * Portuguese (português)
  * Dutch (Nederlands)
  * Greek (ελληνικά)
  * Japanese (日本語)
* [screenshot](http://mike-kfed.github.io/roundcube-thunderbird_labels/)

### INSTALL

#### manual:

1. unpack to plugins directory
1. add `, 'thunderbird_labels'` to `$config['plugins']` in roundcubes `config/config.inc.php`
1. rename `config.inc.php.dist` to `config.inc.php`
1. if you run a custom skin, e.g. `silver` then you should also symlink or copy the skins folder
   of the plugin to the corresponding skins name, for the example given:
   `ln -s plugins/thunderbird_labels/skins/larry plugins/thunderbird_labels/skins/silver`

#### composer:

1. go to your roundcube root dir, setup `composer.json` and run `composer require weird-birds/thunderbird_labels`

### CONFIGURE

See `config.inc.php`

- `tb_label_enable = true/false` (can be changed by user in prefs UI)
- `tb_label_modify_labels = true/false`
- `tb_label_enable_contextmenu = true/false`
- `tb_label_enable_shortcuts = true/false` (can be changed by user in prefs UI)
- `tb_label_style = 'bullets'` or `'thunderbird'`

### Author
Michael Kefeder
<https://github.com/mike-kfed/roundcube-thunderbird_labels>

### History
This plugin is based on a patch I found for roundcube 0.3 a long time ago.

Since roundcube is now able to handle the labels without modification of its source I decided to create a plugin.

There exists a "Tags plugin for RoundCube" <http://sourceforge.net/projects/tagspluginrc/> which does something similar, my plugin emulates thunderbirds behaviour better I think (coloring the message rows for example)

