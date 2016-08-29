
======
Gerrit
======

Gerrit provides web based code review and repository management for the Git version control system.

Sample pillars
==============

Sipmple gerrit service

.. code-block:: yaml

    gerrit:
      server:
        enabled: true
        source:
          engine: http
          address: https://gerrit-ci.gerritforge.com/job/Gerrit-stable-2.13/20/artifact/buck-out/gen/gerrit.war
          hash: 2e17064b8742c4622815593ec496c571

Read more
=========

* https://www.gerritcodereview.com/
* https://github.com/openstack-infra/puppet-gerrit/
* https://gerrit-ci.gerritforge.com/
