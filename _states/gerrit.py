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
    return 'gerrit' if 'gerrit.auth' in __salt__ else False


def project_present(name, description=None, **kwargs):
    '''
    Ensures that the gerrit project exists
    
    :param name: new project name
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
