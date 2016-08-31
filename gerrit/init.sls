{%- if pillar.gerrit is defined %}
include:
{%- if pillar.gerrit.server is defined %}
- gerrit.server
{%- endif %}
{%- if pillar.gerrit.client is defined %}
- gerrit.client
{%- endif %}
{%- endif %}
