{% from "gerrit/map.jinja" import client with context %}
{%- if client.enabled %}

{%- for group_name, group in client.group.iteritems() %}

gerrit_client_group_{{ group_name }}:
  gerrit.group_present:
  - name: {{ group_name }}
  {%- if group.description is defined %}
  - description: {{ group.description }}
  {%- endif %}

{%- endfor %}

{%- endif %}