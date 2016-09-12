{% from "gerrit/map.jinja" import client with context %}
{%- if client.enabled %}

{%- for group_name in client.get('groups', []) %}

gerrit_client_group_{{ group_name }}:
  gerrit.group_present:
  - name: {{ group_name }}

{%- endfor %}

{%- for account_name, account in client.get('user', {}).iteritems() %}

gerrit_client_account_{{ account_name }}:
  gerrit.account_present:
  - name: {{ account_name }}
  - fullname: {{ account.fullname }}
  {%- if account.active is defined %}
  - active: {{ account.active }}
  {%- endif %}
  {%- if account.http_password is defined %}
  - http_password: {{ account.http_password }}
  {%- endif %}
  {%- if account.groups is defined %}
  - groups:
    {%- for group in account.groups %}
    - {{ group }}
    {% endfor %}
  {%- endif %}

{%- endfor %}

{%- endif %}
