{% from "gerrit/map.jinja" import client with context %}
{%- if client.enabled %}

{%- if client.source.engine == 'pkg' %}

gerrit_client_install:
  pkg.installed:
  - names: {{ client.source.pkgs }}

{%- elif client.source.engine == 'pip' %}

{#-
  This separate installation of pbr is a workaround to be able to install Gerrit packages
  offline with local mirrors because setup.py has problems with resolving this dependency.
#}
gerrit_python_pip:
  pkg.installed:
    - name: python-pip

pbr_install:
  pip.installed:
    - name: pbr

gerrit_client_install:
  pip.installed:
    - names:
      - pygerrit
      - "{{ client.get('repo', {}).get('gerritlib', 'git+https://github.com/openstack-infra/gerritlib.git') }}"
      - "{{ client.get('repo', {}).get('jeepyb', 'git+https://github.com/openstack-infra/jeepyb.git') }}"
    - require:
      - pkg: gerrit_python_pip
      - pip: pbr_install

{%- endif %}

gerrit_client_dirs:
  file.directory:
  - names:
    - {{ client.dir.acls }}
    - {{ client.dir.cache }}
    - {{ client.dir.git }}
    - /etc/github
  - makedirs: true

{%- if client.get('try_login', False) %}
{#-
  Ugly workaround to provision user which is possible only over web UI
  See https://groups.google.com/forum/#!topic/repo-discuss/I0SiBjbaojk
#}
gerrit_try_login:
  cmd.run:
    - name: http_proxy='' curl -fsvr -X POST --data "username={{ client.server.user }}&password={{ client.server.password }}" {{ client.server.protocol|default('http') }}://{{ client.server.host }}:{{ client.server.http_port|default(80) }}/login 
{%- endif %}

/etc/github/github-projects.secure.config:
  file.managed:
  - source: salt://gerrit/files/github-projects.secure.config
  - template: jinja

{{ client.config.key }}:
  file.managed:
  - mode: 400
  - contents_pillar: gerrit:client:server:key

{%- endif %}
