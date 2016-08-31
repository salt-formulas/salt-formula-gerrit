{%- from "gerrit/map.jinja" import server with context %}
{%- if server.enabled %}

include:
- gerrit.server.service

{%- for plugin_name, plugin in server.get('plugin', {}).iteritems() %}

{%- if plugin.engine == "http" %}

{{ server.dir.home }}/review_site/plugins/{{ plugin_name }}.jar
  file.managed:
  - source: {{ plugin.address }}
  - user: gerrit2

{%- endif %}

{%- endfor %}

{%- endif %}
