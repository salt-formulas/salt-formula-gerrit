# -*- coding: utf-8 -*-
'''
Module for handling gerrit calls.

:optdepends:    - gerritlib Python adapter
:configuration: This module is not usable until the following are specified
    either in a pillar or in the minion's config file::

        gerrit.host: localhost
        gerrit.user: admin
        gerrit.keyfile: /tmp/key.pub

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
   
    prefix = "gerrit."

    # look in connection_args first, then default to config file
    def get(key, default=None):
        return connection_args.get('connection_' + key,
            __salt__['config.get'](prefix + key, default))

    host = get('host', 'localhost')
    user = get('user', 'localhost')   
    keyfile = get('keyfile', '/tmp/.ssh/id_rsa.pub')   

    g = gerrit.Gerrit(host, user, keyfile=keyfile)


def project_create(name, **kwargs):
    '''
    Create a gerrit project

    :param name: new project name
    :param path: custom repository name for new project. By default generated based on name
    :param namespace_id: namespace for the new project (defaults to user)
    :param description: short project description
    :param issues_enabled:
    :param merge_requests_enabled:
    :param wiki_enabled:
    :param snippets_enabled:
    :param public: if true same as setting visibility_level = 20
    :param visibility_level:
    :param import_url: https://gerrit.tcpcloud.eu/django/django-kedb.gerrit

    CLI Examples:

    .. code-block:: bash

        salt '*' gerrit.project_create namespace/nova description='nova project'
        salt '*' gerrit.project_create namespace/test enabled=False
    
    '''
    ret = {}
    gerrit = auth(**kwargs)

    project = _get_project(gerrit, name)

    if project and not "Error" in project:
        LOG.debug("Project {0} exists".format(name))
        ret[project.get('path_with_namespace')] = project
        return ret

    group_name, name = name.split('/')
    group = group_get(name=group_name)[group_name]
    kwargs['namespace_id'] = group.get('id')
    kwargs['name'] = name
    LOG.debug(kwargs)

    new = gerrit.createproject(**kwargs)
    if not new:
        return {'Error': 'Error creating project %s' % new}
    else:
        LOG.debug(new)
        ret[new.get('path_with_namespace')] = new
        return ret

def project_delete(project, **kwargs):
    '''
    Delete a project (gerrit project-delete)

    :params project: Name or ID

    CLI Examples:

    .. code-block:: bash

        salt '*' gerrit.project_delete c965f79c4f864eaaa9c3b41904e67082
        salt '*' gerrit.project_delete project_id=c965f79c4f864eaaa9c3b41904e67082
        salt '*' gerrit.project_delete name=demo
    '''
    gerrit = auth(**kwargs)

    project = _get_project(gerrit, project)

    if not project:
        return {'Error': 'Unable to resolve project'}

    del_ret = gerrit.deleteproject(project["id"])
    ret = 'Project ID {0} deleted'.format(project["path_with_namespace"])
    ret += ' ({0})'.format(project["path_with_namespace"])

    return ret


def project_get(project_id=None, name=None, **kwargs):
    '''
    Return a specific project

    CLI Examples:

    .. code-block:: bash

        salt '*' gerrit.project_get 323
        salt '*' gerrit.project_get project_id=323
        salt '*' gerrit.project_get name=namespace/repository
    '''
    gerrit = auth(**kwargs)
    ret = {}
    #object_list = project_list(kwargs)

    project = _get_project(gerrit, name or project_id)
    if not project:
        return {'Error': 'Error in retrieving project'}
    ret[project.get('name')] = project
    return ret


def project_list(**connection_args):
    '''
    Return a list of available projects

    CLI Example:

    .. code-block:: bash

        salt '*' gerrit.project_list
    '''
    gerrit = auth(**connection_args)
    ret = {}

    projects = gerrit.listProjects()

    while len(projects) > 0:
        for project in projects:
            ret[project.get('path_with_namespace')] = project
        page += 1
        projects = gerrit.getprojectsall(page=page, per_page=PER_PAGE)
    return ret


def group_list(group_name=None, **connection_args):
    '''
    Return a list of available groups

    CLI Example:

    .. code-block:: bash

        salt '*' gerrit.group_list
    '''
    gerrit = auth(**connection_args)
    ret = {}
    for group in gerrit.listProjects():
        ret[group.get('name')] = group
    return ret


def group_get(id=None, name=None, **connection_args):
    '''
    Return a specific group

    CLI Examples:

    .. code-block:: bash

        salt '*' gerrit.group_get 323
        salt '*' gerrit.group_get name=namespace

    '''
    gerrit = auth(**connection_args)
    ret = {}
    if id == None:
        for group in gerrit.getgroups(group_id=None, page=1, per_page=100):
            if group.get('path') == name or group.get('name') == name:
                ret[group.get('path')] = group
    else:
        group = gerrit.getgroups(id)
        if group != False:
            ret[group.get('path')] = group
    if len(ret) == 0:
        return {'Error': 'Error in retrieving group'}
    return ret

