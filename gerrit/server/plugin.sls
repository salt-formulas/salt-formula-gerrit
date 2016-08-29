{%- from "gerrit/map.jinja" import server with context %}
{%- if server.enabled %}

include:
- gerrit.server.service

gerrit_plugin_dirs:
  file.directory:
  - names:
    - {{ server.dir.home }}/gerrit-plugins
    - {{ server.dir.home }}/review_site/plugins
  - makedirs: true
  - user: gerrit2
  - group: gerrit2
  - require:
    - file: gerrit_home

{% for plugin_name, plugin in server.get('plugin', {}).iteritems() %}

{{ server.dir.home }}/review_site/plugins/{{ plugin_name }}.jar
  file.managed:
  - source: {{ plugin.address }}
  - user: gerrit2
  - require:
    - file: gerrit_plugin_dirs

{%- endfor %}

{%- endif %}
