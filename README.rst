
======
Gerrit
======

Gerrit provides web based code review and repository management for the Git version control system.

Sample pillars
==============

Simple gerrit service

.. code-block:: yaml

    gerrit:
      server:
        enabled: true
        source:
          engine: http
          address: https://gerrit-ci.gerritforge.com/job/Gerrit-stable-2.13/20/artifact/buck-out/gen/gerrit.war
          hash: 2e17064b8742c4622815593ec496c571

Full service setup

.. code-block:: yaml

    gerrit:
      server:
        canonical_web_url: http://10.10.10.148:8082/
        email_private_key: ""
        token_private_key: ""
        initial_user:
          full_name: John Doe
          email: 'mail@jdoe.com'
          username: jdoe
        plugin:
          download-commands:
            engine: gerrit
  #        replication:
  #          engine: gerrit
          reviewnotes:
            engine: gerrit
          singleusergroup:
            engine: gerrit
        ssh_rsa_key: |
          -----BEGIN RSA PRIVATE KEY-----
          MIIEowIBAAKCAQEAs0Y8mxS3dfs5zG8Du5vdBkfOCOng1IEUmFZIirJ8oBgJOd54
          QgmkDFB7oP9eTCgz9k/rix1uJWhhVCMBzrWzH5IODO+tyy/tK66pv2BWtVfTDhBA
          nShOLDNbSIBaV8E/NcrbnQN+b0alp4N7rQnavkOYl+JQncKjz1csmCodirscB9Oj
          rdo6NG9olv9IQd/tDQxEeDyQkoW50aCEWcq7o+QaTzgnlrL+XZEzhzjdcvA9m8go
          ...
          jvMXms60iD/A5OpG33LWHNNzQBP486SxG75LB+Xs5sp5j2/b7VF5LJLhpGiJv9Mk
          ydbuy8iuuvali2uF133kAlLqnrWfVTYQQI1OfW5glOv1L6kv94dU
          -----END RSA PRIVATE KEY-----
        ssh_rsa_key_pub: ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCzRjybFLd1+znMbwO7m90GR84I6eDUgRSYVkiKsnygGAk53nhCCaQMUHug/15MKDP2T+uLHW4laGFUIwHOtbMfkg4M763LL+0rrqm/YFa1V9MOEECdKE4sM1tIgFpXwT81ytudA35vRqWng3utCdq+Q5iX4lCdwqPPVyyYKh2KuxwH06Ot2jo0b2iW/0hB3+0NDER4PJCShbnRoIRZyruj5BpPOCeWsv5dkTOHON1y8D2byCgNGdCBIRx7x9Qb4dKK2F01r0/bfBGxELJzBdQ8XO14bQ7VOd3gTxrccTM4tVS7/uc/vtjiq7MKjnHGf/svbw9bTHAXbXcWXtOlRe51
        email: mail@domain.com
        auth:
          engine: HTTP
        source:
          engine: http
          address: https://gerrit-releases.storage.googleapis.com/gerrit-2.12.4.war
          hash: sha256=45786a920a929c6258de6461bcf03ddec8925577bd485905f102ceb6e5e1e47c
        database:
          engine: postgresql
          host: localhost
          port: 5432
          name: gerrit
          user: gerrit
          password: ${_param:postgresql_gerrit_password}

Gerrit client enforcing projects

.. code-block:: yaml

    gerrit:
      client:
        enabled: True
        server: 
          host: 10.10.10.148
          user: newt
          key: |
            -----BEGIN RSA PRIVATE KEY-----
            MIIEowIBAAKCAQEAs0Y8mxS3dfs5zG8Du5vdBkfOCOng1IEUmFZIirJ8oBgJOd54
            QgmkDFB7oP9eTCgz9k/rix1uJWhhVCMBzrWzH5IODO+tyy/tK66pv2BWtVfTDhBA
            ...
            l1UrxQKBgEklBTuEiDRibKGXQBwlAYvK2He09hWpqtpt9/DVel6s4A1bbTWDHyoP
            jvMXms60iD/A5OpG33LWHNNzQBP486SxG75LB+Xs5sp5j2/b7VF5LJLhpGiJv9Mk
            ydbuy8iuuvali2uF133kAlLqnrWfVTYQQI1OfW5glOv1L6kv94dU
            -----END RSA PRIVATE KEY-----
        project:
          test_salt_project:
            enabled: true

Read more
=========

* https://www.gerritcodereview.com/
* https://gerrit-review.googlesource.com/Documentation/
* https://github.com/openstack-infra/puppet-gerrit/
* https://gerrit-ci.gerritforge.com/
* https://github.com/morucci/exzuul