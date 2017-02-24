{%- from "gerrit/map.jinja" import client with context %}
include:
- gerrit.client.service
{%- if client.group is defined %}
- gerrit.client.group
{%- endif %}
{%- if client.user is defined %}
- gerrit.client.user
{%- endif %}
{%- if client.project is defined %}
- gerrit.client.project
{%- endif %}
