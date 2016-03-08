{%- if pillar.gerrit is defined %}
include:
{%- if pillar.gerrit.server is defined %}
- gerrit.server
{%- endif %}
{%- endif %}
