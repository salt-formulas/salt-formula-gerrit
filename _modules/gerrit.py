# -*- coding: utf-8 -*-
'''
Module for handling gerrit calls.

:optdepends:    - gerritlib Python adapter
:configuration: This module is not usable until the following are specified
    either in a pillar or in the minion's config file::

        gerrit.host: localhost
        gerrit.user: admin
        gerrit.key: |
            -----BEGIN RSA PRIVATE KEY-----
            MIIEowIBAAKCAQEAs0Y8mxS3dfs5zG8Du5vdBkfOCOng1IEUmFZIirJ8oBgJOd54
            ...
            jvMXms60iD/A5OpG33LWHNNzQBP486SxG75LB+Xs5sp5j2/b7VF5LJLhpGiJv9Mk
            ydbuy8iuuvali2uF133kAlLqnrWfVTYQQI1OfW5glOv1L6kv94dU
            -----END RSA PRIVATE KEY-----

'''

from __future__ import absolute_import

import logging
import os

LOG = logging.getLogger(__name__)

# Import third party libs
HAS_GERRIT = False
try:
    from gerritlib import gerrit
    HAS_GERRIT = True
except ImportError:
    pass


def __virtual__():
    '''
    Only load this module if gerrit
    is installed on this minion.
    '''
    if HAS_GERRIT:
        return 'gerrit'
    return False

__opts__ = {}


def auth(**connection_args):
    '''
    Set up gerrit credentials

    Only intended to be used within gerrit-enabled modules
    '''
   
    prefix = "gerrit"

    # look in connection_args first, then default to config file
    def get(key, default=None):
        return connection_args.get('connection_' + key,
            __salt__['config.get'](prefix, {})).get(key, default)

    host = get('host', 'localhost')
    user = get('user', 'admin')
    keyfile = get('keyfile', '/var/cache/salt/minion/gerrit_rsa')   

    gerrit_client = gerrit.Gerrit(host, user, keyfile=keyfile)
    return gerrit_client


def project_create(name, **kwargs):
    '''
    Create a gerrit project

    :param name: new project name

    CLI Examples:

    .. code-block:: bash

        salt '*' gerrit.project_create namespace/nova description='nova project'
    
    '''
    ret = {}
    gerrit_client = auth(**kwargs)

    project = project_get(name, **kwargs)

    if project and not "Error" in project:
        LOG.debug("Project {0} exists".format(name))
        return project

    new = gerrit_client.createProject(name)
    return project_get(name, **kwargs)

def project_get(name, **kwargs):
    '''
    Return a specific project

    CLI Examples:

    .. code-block:: bash

        salt '*' gerrit.project_get projectname
    '''
    gerrit_client = auth(**kwargs)
    ret = {}

    projects = gerrit_client.listProjects()
    if not name in projects:
        return {'Error': 'Error in retrieving project'}
    ret[name] = {'name': name}
    return ret


def project_list(**connection_args):
    '''
    Return a list of available projects

    CLI Example:

    .. code-block:: bash

        salt '*' gerrit.project_list
    '''
    gerrit_client = auth(**connection_args)
    ret = {}

    projects = gerrit_client.listProjects()

    for project in projects:
        ret[project] = {
            'name': project
        }
    return ret


def query(change, **kwargs):
    '''
    Query gerrit

    :param change: Query content

    CLI Examples:

    .. code-block:: bash

        salt '*' gerrit.query 'status:open project:tools/gerrit limit:2'
    
    '''
    ret = {}
    gerrit_client = auth(**kwargs)
    msg = gerrit_client.query(change)
    ret['query'] = msg
    return ret
