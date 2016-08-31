{% from "gerrit/map.jinja" import client with context %}
{%- if client.enabled %}

gerrit_client_install:
  pkg.installed:
  - names: {{ client.pkgs }}

/etc/salt/minion.d/_gerrit.conf:
  file.managed:
  - source: salt://gerrit/files/_gerrit.conf
  - template: jinja

/var/cache/salt/minion/gerrit_rsa:
  file.managed:
  - contents_pillar: gerrit:client:server:key

{%- for project_name, project in client.project.iteritems() %}

gerrit_client_project_{{ project_name }}:
  gerrit.project_present:
  - name: {{ project_name }}

{%- endfor %}

{%- endif %}
