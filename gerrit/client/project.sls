{% from "gerrit/map.jinja" import client with context %}
{%- if client.enabled %}

/srv/jeepyb/projects.ini:
  file.managed:
  - source: salt://gerrit/files/projects.ini
  - template: jinja
  - require_in:
    - cmd: gerrit_client_enforce_projects

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

gerrit_client_enforce_projects:
  cmd.run:
  - name: manage-projects -v
  - env:
    - PROJECTS_INI: "/srv/jeepyb/projects.ini"
    - PROJECTS_YAML: "/srv/jeepyb/projects.yaml"
    - GERRIT_CONFIG: "{{ client.dir.gerrit_config }}"
    - GERRIT_SECURE_CONFIG: "{{ client.dir.gerrit_secure_config }}"

{%- endif %}
