gerrit:
  client:
    enabled: true
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
    server:
      user: "jdoe"
      password: "passw0rd"
      email: "jdoe@email.com"
      host: 0.0.0.0
      protocol: "http"
      http_port: 80
      ssh_port: 22