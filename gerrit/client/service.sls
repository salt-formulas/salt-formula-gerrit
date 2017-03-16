{% from "gerrit/map.jinja" import client with context %}
{%- if client.enabled %}

{%- if client.source.engine == 'pkg' %}

gerrit_client_install:
  pkg.installed:
  - names: {{ client.source.pkgs }}

{%- elif client.source.engine == 'pip' %}

gerrit_python_pip:
  pkg.installed:
    - name: python-pip

gerrit_client_install:
  pip.installed:
    - names:
      - pygerrit
      - "git+https://github.com/openstack-infra/gerritlib.git"
      - "git+https://github.com/openstack-infra/jeepyb.git"
    - require:
      - pkg: gerrit_python_pip

{%- endif %}

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
