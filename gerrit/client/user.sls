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

{%- for account_name, account in client.user.iteritems() %}

gerrit_client_account_{{ account_name }}:
  gerrit.account_present:
  - name: {{ account_name }}
  - fullname: {{ account.fullname }}
  - active: {{ account.get('active', True) }}
  {%- if account.email is defined %}
  - email: {{ account.email }}
  {%- endif %}
  {%- if account.http_password is defined %}
  - http_password: {{ account.http_password }}
  {%- endif %}
  {%- if account.ssh_key is defined %}
  - ssh_key: {{ account.ssh_key }}
  {%- endif %}
  {%- if account.groups is defined %}
  - groups:
    {%- for group in account.groups %}
    - {{ group }}
    {% endfor %}
  {%- endif %}

{%- endfor %}

{%- endif %}