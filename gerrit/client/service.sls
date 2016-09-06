{% from "gerrit/map.jinja" import client with context %}
{%- if client.enabled %}

gerrit_client_install:
  pkg.installed:
  - names: {{ client.pkgs }}

gerrit_client_dirs:
  file.directory:
  - names: 
    - {{ client.dir.acls }}
    - {{ client.dir.cache }}
    - {{ client.dir.git }}
    - /etc/github
  - makedirs: true

/etc/salt/minion.d/_gerrit.conf:
  file.managed:
  - source: salt://gerrit/files/_gerrit.conf
  - template: jinja

/etc/github/github-projects.secure.config:
  file.managed:
  - source: salt://gerrit/files/github-projects.secure.config
  - template: jinja

{{ client.config.key }}:
  file.managed:
  - mode: 400
  - contents_pillar: gerrit:client:server:key

{%- endif %}
