# -*- coding: utf-8 -*-
'''
Management of gerrit projects
==============================

:depends:   - gerritlib Python module
:configuration: See :py:mod:`salt.modules.gerrit` for setup instructions.

.. code-block:: yaml

    gerrit project:
      gerrit.project_present:
      - name: gerrit project

'''


def __virtual__():
    '''
    Only load if the gerrit module is in __salt__
    '''
    return 'gerrit' if 'gerrit.account_create' in __salt__ else False


def account_present(name, fullname, email=None, active=None, groups=[], ssh_key=None, http_password=None, **kwargs):
    '''
    Ensures that the gerrit account exists
    
    :param name: username
    :param fullname: fullname
    :param email: email
    :param active: active
    :param groups: array of strings
        groups:
            - Non-Interactive Users
            - Testers
    :param ssh_key: public ssh key
    :param http_password: http password

    '''
    ret = {'name': name,
           'changes': {},
           'result': True,
           'comment': 'Account "{0}" already exists'.format(name)}

    # Check if account is already present
    account = __salt__['gerrit.account_get'](name, **kwargs)

    if 'Error' not in account:
        # Update account
        __salt__['gerrit.account_update'](name, fullname, email, active, groups, ssh_key, http_password, **kwargs)
        ret['comment'] = 'Account "{0}" has been updated'.format(name)
        ret['changes']['Account'] = 'Updated'
    else:
        # Create account
        __salt__['gerrit.account_create'](name, fullname, email, active, groups, ssh_key, http_password, **kwargs)
        ret['comment'] = 'Account "{0}" has been added'.format(name)
        ret['changes']['Account'] = 'Created'
    return ret


def group_present(name, description=None, **kwargs):
    '''
    Ensures that the gerrit group exists
    
    :param name: group name
    '''
    ret = {'name': name,
           'changes': {},
           'result': True,
           'comment': 'Group "{0}" already exists'.format(name)}

    # Check if group is already present
    group = __salt__['gerrit.group_get'](name, **kwargs)

    if 'Error' not in group:
        # Update group
        pass
    else:
        # Create group
        __salt__['gerrit.group_create'](name, description, **kwargs)
        ret['comment'] = 'Group "{0}" has been added'.format(name)
        ret['changes']['Group'] = 'Created'
    return ret


def project_present(name, description=None, **kwargs):
    '''
    Ensures that the gerrit project exists
    
    :param name: project name
    :param description: short project description
    '''
    ret = {'name': name,
           'changes': {},
           'result': True,
           'comment': 'Project "{0}" already exists'.format(name)}

    # Check if project is already present
    project = __salt__['gerrit.project_get'](name=name, **kwargs)

    if 'Error' not in project:
        #update project
        pass
    else:
        # Create project
        __salt__['gerrit.project_create'](name, **kwargs)
        ret['comment'] = 'Project "{0}" has been added'.format(name)
        ret['changes']['Project'] = 'Created'
    return ret
