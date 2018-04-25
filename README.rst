
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
              receive_timeout: 5min
        sshd:
          threads: 64
          batch_threads: 16
          max_connections_per_user: 64
        database:
          engine: postgresql
          host: localhost
          port: 5432
          name: gerrit
          user: gerrit
          password: ${_param:postgresql_gerrit_password}
          pool_limit: 250
          pool_max_idle: 16 

Gerrit change auto abandon

.. code-block:: yaml

    gerrit:
      server:
        change_cleanup:
          abandon_after: 3months


Gerrit client enforcing groups

.. code-block:: yaml

    gerrit:
      client:
        group:
          Admin001:
            description: admin 01
          Admin002:
            description: admin 02


Gerrit client enforcing users, install using pip

.. code-block:: yaml

    gerrit:
      client:
        source:
          engine: pip
        user:
          jdoe:
            fullname: John Doe
            email: "jdoe@domain.com"
            ssh_key: ssh-rsa
            http_password: password
            groups:
            - Admin001


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
          email: "Project Creator <infra@lists.domain.com>"
        project:
          test_salt_project:
            enabled: true

Gerrit client enforcing project, full project example

.. code-block:: yaml

    gerrit:
      client:
        enabled: True
        project:
          test_salt_project:
            enabled: true
            access:
              "refs/heads/*":
                actions:
                - name: abandon
                  group: openstack-salt-core
                - name: create
                  group: openstack-salt-release
                labels:
                - name: Code-Review
                  group: openstack-salt-core
                  score: -2..+2
                - name: Workflow
                  group: openstack-salt-core
                  score: -1..+1
              "refs/tags/*":
                actions:
                - name: pushSignedTag
                  group: openstack-salt-release
                  force: true
            inherit_access: All-Projects
            require_change_id: true
            require_agreement: true
            merge_content: true
            action: "fast forward only"


.. code-block:: yaml

    gerrit:
      client:
        enabled: True
        group:
          groupname:
            enabled: true
            members:
            - username
        account:
          username:
            enabled: true
            full_name: hovno
            email: mail@newt.cz
            public_key: rsassh
            http_password: passwd

Gerrit client proxy

.. code-block:: yaml

    gerrit:
      client:
        proxy:
          http_proxy: http://192.168.10.15:8000
          https_proxy: http://192.168.10.15:8000
          no_proxy: 192.168.10.90

Sample project access

.. code-block:: yaml

    [access "refs/*"]
      read = group Administrators
      read = group Anonymous Users
    [access "refs/for/refs/*"]
      push = group Registered Users
      pushMerge = group Registered Users
    [access "refs/heads/*"]
      create = group Administrators
      create = group Project Owners
      forgeAuthor = group Registered Users
      forgeCommitter = group Administrators
      forgeCommitter = group Project Owners
      push = group Administrators
      push = group Project Owners
      label-Code-Review = -2..+2 group Administrators
      label-Code-Review = -2..+2 group Project Owners
      label-Code-Review = -1..+1 group Registered Users
      label-Verified = -1..+1 group Non-Interactive Users
      submit = group Administrators
      submit = group Project Owners
      editTopicName = +force group Administrators
      editTopicName = +force group Project Owners
    [access "refs/meta/config"]
      exclusiveGroupPermissions = read
      read = group Administrators
      read = group Project Owners
      push = group Administrators
      push = group Project Owners
      label-Code-Review = -2..+2 group Administrators
      label-Code-Review = -2..+2 group Project Owners
      submit = group Administrators
      submit = group Project Owners
    [access "refs/tags/*"]
      pushTag = group Administrators
      pushTag = group Project Owners
      pushSignedTag = +force group Administrators
      pushSignedTag = group Project Owners
    [label "Code-Review"]
      function = MaxWithBlock
      copyMinScore = true
      value = -2 This shall not be merged
      value = -1 I would prefer this is not merged as is
      value =  0 No score
      value = +1 Looks good to me, but someone else must approve
      value = +2 Looks good to me, approved
    [label "Verified"]
      function = MaxWithBlock
      copyMinScore = true
      value = -1 Fails
      value =  0 No score
      value = +1 Verified

Read more
=========

* https://www.gerritcodereview.com/
* https://gerrit-review.googlesource.com/Documentation/
* https://github.com/openstack-infra/puppet-gerrit/
* https://gerrit-ci.gerritforge.com/
* https://github.com/morucci/exzuul

Documentation and Bugs
======================

To learn how to install and update salt-formulas, consult the documentation
available online at:

    http://salt-formulas.readthedocs.io/

In the unfortunate event that bugs are discovered, they should be reported to
the appropriate issue tracker. Use Github issue tracker for specific salt
formula:

    https://github.com/salt-formulas/salt-formula-gerrit/issues

For feature requests, bug reports or blueprints affecting entire ecosystem,
use Launchpad salt-formulas project:

    https://launchpad.net/salt-formulas

You can also join salt-formulas-users team and subscribe to mailing list:

    https://launchpad.net/~salt-formulas-users

Developers wishing to work on the salt-formulas projects should always base
their work on master branch and submit pull request against specific formula.

    https://github.com/salt-formulas/salt-formula-gerrit

Any questions or feedback is always welcome so feel free to join our IRC
channel:

    #salt-formulas @ irc.freenode.net
