{%- from "gerrit/map.jinja" import server with context %}
{%- if server.enabled %}

gerrit_packages:
  pkg.installed:
  - names: {{ server.pkgs }}

gerrit_user:
  user.present:
  - name: gerrit2
#  - system: True
  - home: {{ server.dir.home }}

gerrit_home:
  file.directory:
  - names: 
    - {{ server.dir.home }}/.ssh
    - {{ server.dir.home }}/gerrit-wars
    - {{ server.dir.site }}/bin
    - {{ server.dir.site }}/cache
    - {{ server.dir.site }}/etc/its
    - {{ server.dir.site }}/hooks
    - {{ server.dir.site }}/lib
    - {{ server.dir.site }}/logs
    - {{ server.dir.site }}/static
    - /var/log/gerrit
  - makedirs: true
  - user: gerrit2
  - group: gerrit2
  - require:
    - user: gerrit_user
    - pkg: gerrit_packages

{{ server.dir.site }}/etc/gerrit.config:
  file.managed:
  - source: salt://gerrit/files/gerrit.config
  - user: gerrit2
  - group: gerrit2
  - template: jinja
  - require:
    - file: gerrit_home

{{ server.dir.site }}/etc/secure.config:
  file.managed:
  - source: salt://gerrit/files/secure.config
  - user: gerrit2
  - group: gerrit2
  - template: jinja
  - require:
    - file: gerrit_home

{{ server.dir.site }}/etc/its/actions.config:
  file.managed:
  - source: salt://gerrit/files/actions.config
  - user: gerrit2
  - group: gerrit2
  - template: jinja
  - require:
    - file: gerrit_home

{%- if server.get('replication', False) %}

{{ server.dir.site }}/etc/replication.config:
  file.managed:
  - source: salt://gerrit/files/replication.config
  - user: gerrit2
  - group: gerrit2
  - template: jinja
  - require:
    - file: gerrit_home

{% endif %}

{{ server.dir.site }}/etc/ssh_project_rsa_key:
  file.managed:
  - contents_pillar: gerrit:server:ssh_rsa_key
  - user: gerrit2
  - group: gerrit2
  - mode: 600
  - require:
    - file: gerrit_home

{{ server.dir.site }}/etc/ssh_project_rsa_key.pub:
  file.managed:
  - contents_pillar: gerrit:server:ssh_rsa_key_pub
  - user: gerrit2
  - group: gerrit2
  - mode: 644
  - require:
    - file: gerrit_home

{{ server.dir.site }}/etc/ssh_host_rsa_key:
  file.managed:
  - contents_pillar: gerrit:server:ssh_rsa_key
  - user: gerrit2
  - group: gerrit2
  - mode: 600
  - require:
    - file: gerrit_home

{{ server.dir.site }}/etc/ssh_host_rsa_key.pub:
  file.managed:
  - contents_pillar: gerrit:server:ssh_rsa_key_pub
  - user: gerrit2
  - group: gerrit2
  - mode: 644
  - require:
    - file: gerrit_home

{{ server.dir.site }}/etc/ssh_welcome_rsa_key:
  file.managed:
  - contents_pillar: gerrit:server:ssh_rsa_key
  - user: gerrit2
  - group: gerrit2
  - mode: 600
  - require:
    - file: gerrit_home

{{ server.dir.site }}/etc/ssh_welcome_rsa_key.pub:
  file.managed:
  - contents_pillar: gerrit:server:ssh_rsa_key_pub
  - user: gerrit2
  - group: gerrit2
  - mode: 644
  - require:
    - file: gerrit_home

{{ server.dir.home }}/.ssh/id_rsa:
  file.managed:
  - contents_pillar: gerrit:server:ssh_rsa_key
  - user: gerrit2
  - group: gerrit2
  - mode: 600
  - require:
    - file: gerrit_home

{{ server.dir.home }}/.ssh/id_rsa.pub:
  file.managed:
  - contents_pillar: gerrit:server:ssh_rsa_key_pub
  - user: gerrit2
  - group: gerrit2
  - mode: 644
  - require:
    - file: gerrit_home

{% if server.source.engine == "http" %}

{{ server.dir.site }}/bin/gerrit.war:
  file.managed:
  - source: {{ server.source.address }}
  - source_hash: {{ server.source.hash }}
  - user: gerrit2
  - group: gerrit2
  - require:
    - file: gerrit_home
  - require_in:
    - cmd: gerrit_server_initial_init

{%- endif %}

gerrit_server_initial_init:
  cmd.run:
  - name: /usr/bin/java -jar {{ server.dir.site }}/bin/gerrit.war init -d {{ server.dir.site }} --batch --no-auto-start
  - unless: /usr/bin/test -f /etc/init.d/gerrit
  - require:
    - file: {{ server.dir.site }}/etc/gerrit.config
    - file: {{ server.dir.site }}/etc/secure.config

gerrit_server_initial_index:
  cmd.run:
  - name: /usr/bin/java -jar {{ server.dir.site }}/bin/gerrit.war reindex -d {{ server.dir.site }} --threads {{ server.reindex_threads }}
  - watch:
    - cmd: gerrit_server_initial_init

/etc/default/gerritcodereview:
  file.managed:
  - source: salt://gerrit/files/gerritcodereview
  - user: gerrit2
  - group: gerrit2
  - template: jinja
  - require:
    - file: gerrit_home

/lib/systemd/system/gerrit.service:
  file.managed:
  - source: salt://gerrit/files/gerrit.systemd
  - user: gerrit2
  - group: gerrit2
  - template: jinja
  - require:
    - file: gerrit_home

gerrit_server_service_symlink:
  file.symlink:
  - name: /etc/init.d/{{ server.service }}
  - target: {{ server.dir.site }}/bin/gerrit.sh

gerrit_server_service:
  service.running:
  - name: {{ server.service }}
  - enable: true
  - require:
    - file: gerrit_server_service_symlink
    - cmd: gerrit_server_initial_index

gerrit_server_known_host:
  ssh_known_hosts.present:
    - name: localhost
    - port: 29418
    - user: gerrit2
    - require:
      - file: gerrit_home

{%- endif %}
