{% from "gerrit/map.jinja" import client with context %}
{%- if client.enabled %}

{{ client.dir.project_config }}/projects.ini:
  file.managed:
  - source: salt://gerrit/files/projects.ini
  - template: jinja
  - require_in:
    - cmd: gerrit_client_enforce_projects
{%- if client.dir.project_config == "/srv/jeepyb" %}
/srv/jeepyb/projects.yaml:
  file.managed:
  - source: salt://gerrit/files/projects.yaml
  - template: jinja
  - require_in:
    - cmd: gerrit_client_enforce_projects

{%- for project_name, project in client.project.iteritems() %}

{{ client.dir.acls }}/{{ project_name }}.config:
  file.managed:
  - source: salt://gerrit/files/project.config
  - template: jinja
  - makedirs: true
  - defaults:
      project_name: {{ project.get('name', project_name) }}
  - require_in:
    - cmd: gerrit_client_enforce_projects

{#
gerrit_client_project_{{ project_name }}:
  gerrit.project_present:
  - name: {{ project_name }}
#}

{%- endfor %}
{%- endif %}
gerrit_client_enforce_projects:
  cmd.run:
  - name: manage-projects -d -v 2>&1 | tee {{ client.dir.project_config }}/jeepyb.log
  - env:
    - PROJECTS_INI: "{{ client.dir.project_config }}/projects.ini"
    - PROJECTS_YAML: "{{ client.dir.project_config }}/projects.yaml"
    - GERRIT_CONFIG: "{{ client.dir.gerrit_config }}"
    - GERRIT_SECURE_CONFIG: "{{ client.dir.gerrit_secure_config }}"
    - GIT_COMMITTER_EMAIL: "{{ client.server.email }}"

{%- endif %}
