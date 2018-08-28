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
    - {{ server.dir.home }}/gerrit-plugins
    - {{ server.dir.site }}/bin
    - {{ server.dir.site }}/cache
    - {{ server.dir.site }}/etc/its
    - {{ server.dir.site }}/hooks
    - {{ server.dir.site }}/lib
    - {{ server.dir.site }}/logs
    - {{ server.dir.site }}/plugins
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
  - replace: False
  - require:
    - file: gerrit_home

{{ server.dir.site }}/etc/secure.config:
  file.managed:
  - source: salt://gerrit/files/secure.config
  - user: gerrit2
  - group: gerrit2
  - template: jinja
  - replace: False
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

{%- if server.plugin.replication is defined %}

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

{%- if server.source.engine == "http" %}

{{ server.dir.home }}/gerrit.war:
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
  - name: /usr/bin/java -jar {{ server.dir.home }}/gerrit.war init -d {{ server.dir.site }} --batch --no-auto-start{% for plugin_name, plugin in server.get('plugin', {}).iteritems() %}{% if plugin.engine == "gerrit" %} --install-plugin {{ plugin_name }}{% endif %}{% endfor %}
  - unless: /usr/bin/test -f {{ server.dir.home }}/.gerrit-configured
  - runas: gerrit2
  - require:
    - file: {{ server.dir.site }}/etc/gerrit.config
    - file: {{ server.dir.site }}/etc/secure.config

gerrit_server_initial_index:
  cmd.run:
  - name: /usr/bin/java -jar {{ server.dir.home }}/gerrit.war reindex -d {{ server.dir.site }} --threads {{ server.reindex_threads }}
  - unless: /usr/bin/test -f {{ server.dir.home }}/.gerrit-configured
  - runas: gerrit2
  - require:
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

{%- set initial_accounts_queries = [
  "insert into ACCOUNTS values (NULL, 'admin', NULL, NULL, 'N', NULL, NULL, NULL, NULL, 25, 'N', 'N', 'Y', 'N', NULL, 'Y', 'N', 'admin@ci.localdomain', '2015-05-28 11:00:30.001', 1)",
  "insert into ACCOUNT_GROUP_MEMBERS values (1, 1)",
  "insert into ACCOUNT_EXTERNAL_IDS values (1, 'admin@ci.localdomain', NULL, 'username:admin')",
  "insert into ACCOUNT_EXTERNAL_IDS values (1, 'admin@ci.localdomain', NULL, 'mailto:admin@ci.localdomain')",
  "insert into ACCOUNTS values (NULL, 'zuul', NULL, NULL, 'N', NULL, NULL, NULL, NULL, 25, 'N', 'N', 'Y', 'N', NULL, 'Y', 'N', 'zuul@ci.localdomain', '2015-05-28 11:00:30.001', 2)",
  "insert into ACCOUNT_GROUP_MEMBERS values (2, 4)",
  "insert into ACCOUNT_EXTERNAL_IDS values (2, 'zuul@ci.localdomain', NULL, 'username:zuul')",
  "insert into ACCOUNT_EXTERNAL_IDS values (2, 'zuul@ci.localdomain', NULL, 'mailto:zuul@ci.localdomain')",
  "insert into account_ssh_keys values ('"+server.ssh_rsa_key_pub+"', 'Y', 2, 1)",
  "insert into account_ssh_keys values ('"+server.ssh_rsa_key_pub+"', 'Y', 1, 1)",
] %}

{%- for query in initial_accounts_queries %}

gerrit_server_initial_accounts_{{ loop.index }}:
  cmd.run:
  - name: /usr/bin/java -jar {{ server.dir.home }}/gerrit.war gsql -d {{ server.dir.site }} -c "{{ query }}"
  - unless: /usr/bin/test -f {{ server.dir.home }}/.gerrit-configured
  - runas: gerrit2
  - require:
    - service: gerrit_server_service
  - require_in:
    - file: gerrit_server_configured

{%- endfor %}

gerrit_server_configured:
  file.touch:
  - name: {{ server.dir.home }}/.gerrit-configured
  - unless: /usr/bin/test -f {{ server.dir.home }}/.gerrit-configured
  - require:
    - service: gerrit_server_service

gerrit_server_service_available:
  cmd.run:
    - name: until nc -z localhost 29418; do sleep 1; done
    - timeout: 60
    - require:
      - service: gerrit_server_service

gerrit_server_known_host:
  ssh_known_hosts.present:
    - name: localhost
    - port: 29418
    - user: gerrit2
    - hash_known_hosts: false
    - require:
      - file: gerrit_home
      - cmd: gerrit_server_service_available

{%- endif %}
