{% from "gerrit/map.jinja" import client with context %}
{%- if client.enabled %}

/srv/jeepyb/projects.ini:
  file.managed:
  - source: salt://gerrit/files/projects.ini
  - template: jinja

jeepyb_projects_ini_env:
  environ.setenv:
  - name: PROJECTS_INI
  - value: /srv/jeepyb/projects.ini
  - update_minion: True
  - require:
    - file: /srv/jeepyb/projects.ini

/srv/jeepyb/projects.yaml:
  file.managed:
  - source: salt://gerrit/files/projects.yaml
  - template: jinja

jeepyb_projects_yaml_env:
  environ.setenv:
  - name: PROJECTS_YAML
  - value: /srv/jeepyb/projects.yaml
  - update_minion: True
  - require:
    - file: /srv/jeepyb/projects.yaml

jeepyb_setup_projects:
  environ.setenv:
  - name: PROJECTS_YAML
  - value: /srv/jeepyb/projects.yaml
  - update_minion: True
  - require:
    - environ: jeepyb_projects_ini_env
    - environ: jeepyb_projects_yaml_env

{%- for project_name, project in client.project.iteritems() %}

{{ client.dir.acls }}/{{ project_name }}.config:
  file.managed:
  - source: salt://gerrit/files/project.config
  - template: jinja
  - defaults:
      project_name: {{ project_name }}

gerrit_client_project_{{ project_name }}:
  gerrit.project_present:
  - name: {{ project_name }}

{%- endfor %}

{%- endif %}
