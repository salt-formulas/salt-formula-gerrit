# -*- coding: utf-8 -*-
'''
Module for handling gerrit calls.

:optdepends:    - gerritlib/pygerrit Python adapter
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

Examples:
- gerrit_account:
    username: Jenkins
    fullname: Jenkins continuous integration tool
    email: admin@example.com
    groups:
        - Non-Interactive Users
        - Testers
    gerrit_url: http://gerrit.example.com:8080/
    gerrit_admin_username: dicky
    gerrit_admin_password: b0sst0nes
'''

from __future__ import absolute_import

import json
import logging
import os
import urllib

import pygerrit.rest
import requests.auth

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


# COMMON


def value_from_param(field, spec, param_value):
    if 'choices' in spec:
        if param_value not in spec['choices']:
            raise ValueError(
                "'%s' is not valid for field %s" % (param_value, field))
        value = param_value.upper()
    else:
        value = param_value
    return value


def value_from_config_info(field, spec, info_value):
    if isinstance(info_value, dict):
        # This is a ConfigParameterInfo field. We need to figure out if the
        # value is TRUE, FALSE or INHERIT.
        if 'configured_value' in info_value:
            value = info_value['configured_value']
        else:
            value = 'INHERIT'
    else:
        value = info_value
    return value


def get_boolean(gerrit, path):
    response = gerrit.get(path)
    if response == 'ok':
        value = True
    elif response == '':
        value = False
    else:
        raise AnsibleGerritError(
            "Unexpected response for %s: %s" % (path, response))
    return value


def get_list(gerrit, path):
    values = gerrit.get(path)
    return values


def get_string(gerrit, path):
    try:
        value = gerrit.get(path)
    except requests.exceptions.HTTPError as e:
        if e.response.status_code == 404:
            logging.debug("Ignoring exception %s", e)
            logging.debug("Got %s", e.response.__dict__)
            value = None
        else:
            raise
    return value


def set_boolean(gerrit, path, value):
    if value:
        gerrit.put(path)
    else:
        gerrit.delete(path)


def set_string(gerrit, path, value, field_name=None):
    field_name = field_name or os.path.basename(path)

    # Setting to '' is equivalent to deleting, so we have no need for the
    # DELETE method.
    headers = {'content-type': 'application/json'}
    data = json.dumps({field_name: value})
    gerrit.put(path, data=data, headers=headers)


def maybe_update_field(gerrit, path, field, gerrit_value, ansible_value,
                       type='str', gerrit_api_path=None):

    gerrit_api_path = gerrit_api_path or field
    fullpath = path + '/' + gerrit_api_path

    if gerrit_value == ansible_value:
        logging.info("Not updating %s: same value specified: %s", fullpath,
                     gerrit_value)
        value = gerrit_value
        changed = False
    elif ansible_value is None:
        logging.info("Not updating %s: no value specified, value stays as %s",
                     fullpath, gerrit_value)
        value = gerrit_value
        changed = False
    else:
        logging.info("Changing %s from %s to %s", fullpath, gerrit_value,
                     ansible_value)
        if type == 'str':
            set_string(gerrit, fullpath, ansible_value, field_name=field)
        elif type == 'bool':
            set_boolean(gerrit, fullpath, ansible_value)
        else:
            raise AssertionError("Unknown Ansible parameter type '%s'" % type)

        value = ansible_value
        changed = True
    return value, changed

# END COMMON


def gerrit_connection(**connection_args):

    prefix = "gerrit"

    # look in connection_args first, then default to config file
    def get(key, default=None):
        return connection_args.get(
            'connection_' + key,
            __salt__['config.get'](prefix, {})).get(key, default)

    host = get('host', 'localhost')
    username = get('user', 'admin')
    password = get('password', 'admin')

    auth = requests.auth.HTTPDigestAuth(
        username, password)

    gerrit = pygerrit.rest.GerritRestAPI(
        url=host, auth=auth)

    return gerrit


def create_account(gerrit, username=None):
    # Although we could pass an AccountInput entry here to set details in one
    # go, it's left up to the update_account() function, to avoid having a
    # totally separate code path for create vs. update.
    account_info = gerrit.put('/accounts/%s' % quote(username))
    return account_info


def create_account_email(gerrit, account_id, email, preferred=False,
                         no_confirmation=False):
    logging.info('Creating email %s for account %s', email, account_id)

    email_input = {
        # Setting 'email' is optional (it's already in the URL) but it's good
        # to double check that the email is encoded in the URL properly.
        'email': email,
        'preferred': preferred,
        'no_confirmation': no_confirmation,
    }
    logging.debug(email_input)

    path = 'accounts/%s/emails/%s' % (account_id, quote(email))
    headers = {'content-type': 'application/json'}
    gerrit.post(path, data=json.dumps(email_input), headers=headers)


def create_account_ssh_key(gerrit, account_id, ssh_public_key):
    logging.info('Creating SSH key %s for account %s', ssh_public_key,
                 account_id)

    path = 'accounts/%s/sshkeys' % (account_id)
    gerrit.post(path, data=ssh_public_key)


def create_group_membership(gerrit, account_id, group_id):
    logging.info('Creating membership of %s in group %s', account_id, group_id)
    path = 'groups/%s/members/%s' % (quote(group_id), account_id)
    gerrit.put(path)


def ensure_only_member_of_these_groups(gerrit, account_id, ansible_groups):
    path = 'accounts/%s' % account_id
    group_info_list = get_list(gerrit, path + '/groups')

    changed = False
    gerrit_groups = []
    for group_info in group_info_list:
        if group_info['name'] in ansible_groups:
            logging.info("Preserving %s membership of group %s", path,
                         group_info)
            gerrit_groups.append(group_info['name'])
        else:
            logging.info("Removing %s from group %s", path, group_info)
            membership_path = 'groups/%s/members/%s' % (
                quote(group_info['id']), account_id)
            try:
                gerrit.delete(membership_path)
                changed = True
            except requests.exceptions.HTTPError as e:
                if e.response.status_code == 404:
                    # This is a kludge, it'd be better to work out in advance
                    # which groups the user is a member of only via membership
                    # in a different. That's not trivial though with the
                    # current API Gerrit provides.
                    logging.info(
                        "Ignored %s; assuming membership of this group is due "
                        "to membership of a group that includes it.", e)
                else:
                    raise

    # If the user gave group IDs instead of group names, this will
    # needlessly recreate the membership. The only actual issue will be that
    # Ansible reports 'changed' when nothing really did change, I think.
    #
    # We might receive [""] when the user tries to pass in an empty list, so
    # handle that.
    for new_group in set(ansible_groups).difference(gerrit_groups):
        if len(new_group) > 0:
            create_group_membership(gerrit, account_id, new_group)
            gerrit_groups.append(new_group)
            changed = True

    return gerrit_groups, changed


def ensure_only_one_account_email(gerrit, account_id, email):
    path = 'accounts/%s' % account_id
    email_info_list = get_list(gerrit, path + '/emails')

    changed = False
    found_email = False
    for email_info in email_info_list:
        existing_email = email_info['email']
        if existing_email == email:
            # Since we're deleting all emails except this one, there's no need
            # to care whether it's the 'preferred' one. It soon will be!
            logging.info("Keeping %s email %s", path, email)
            found_email = True
        else:
            logging.info("Removing %s email %s", path, existing_email)
            gerrit.delete(path + '/emails/%s' % quote(existing_email))
            changed = True

    if len(email) > 0 and not found_email:
        create_account_email(gerrit, account_id, email,
                             preferred=True, no_confirmation=True)
        changed = True

    return email, changed


def ensure_only_one_account_ssh_key(gerrit, account_id, ssh_public_key):
    path = 'accounts/%s' % account_id
    ssh_key_info_list = get_list(gerrit, path + '/sshkeys')

    changed = False
    found_ssh_key = False
    for ssh_key_info in ssh_key_info_list:
        if ssh_key_info['ssh_public_key'] == ssh_public_key:
            logging.info("Keeping %s SSH key %s", path, ssh_key_info)
            found_ssh_key = True
        else:
            logging.info("Removing %s SSH key %s", path, ssh_key_info)
            gerrit.delete(path + '/sshkeys/%i' % ssh_key_info['seq'])
            changed = True

    if len(ssh_public_key) > 0 and not found_ssh_key:
        create_account_ssh_key(gerrit, account_id, ssh_public_key)
        changed = True

    return ssh_public_key, changed


def update_account(gerrit, username=None, **params):
    change = False

    try:
        account_info = gerrit.get('/accounts/%s' % quote(username))
    except requests.exceptions.HTTPError as e:
        if e.response.status_code == 404:
            logging.info("Account %s not found, creating it.", username)
            account_info = create_account(gerrit, username)
            change = True
        else:
            raise

    logging.debug(
        'Existing account info for account %s: %s', username,
        json.dumps(account_info, indent=4))

    account_id = account_info['_account_id']
    path = 'accounts/%s' % account_id

    output = {}
    output['id'] = account_id

    fullname, fullname_changed = maybe_update_field(
        gerrit, path, 'name', account_info.get('name'), params.get('fullname'))
    output['fullname'] = fullname
    change |= fullname_changed

    # Ansible sets the value of params that the user did not provide to None.

    if params.get('active') is not None:
        active = get_boolean(gerrit, path + '/active')
        active, active_changed = maybe_update_field(
            gerrit, path, 'active', active, params['active'], type='bool')
        output['active'] = active
        change |= active_changed

    if params.get('email') is not None:
        email, emails_changed = ensure_only_one_account_email(
            gerrit, account_id, params['email'])
        output['email'] = email
        change |= emails_changed

    if params.get('groups') is not None:
        groups, groups_changed = ensure_only_member_of_these_groups(
            gerrit, account_id, params['groups'])
        output['groups'] = groups
        change |= groups_changed

    if params.get('http_password') is not None:
        http_password = get_string(gerrit, path + '/password.http')
        http_password, http_password_changed = maybe_update_field(
            gerrit, path, 'http_password', http_password,
            params.get('http_password'),
            gerrit_api_path='password.http')
        output['http_password'] = http_password
        change |= http_password_changed

    if params.get('ssh_key') is not None:
        ssh_key, ssh_keys_changed = ensure_only_one_account_ssh_key(
            gerrit, account_id,  params['ssh_key'])
        output['ssh_key'] = ssh_key
        change |= ssh_keys_changed

    return output, change


def user_create(username, fullname,
                email, groups=[], **kwargs):
    '''
    Create a gerrit project

    :param username: username
    :param fullname: fullname
    :param email: email
    :param groups: array of strings
        groups:
            - Non-Interactive Users
            - Testers
    CLI Examples:

    .. code-block:: bash

        salt '*' gerrit.user_create namespace/nova description='nova project'

    '''

    gerrit_client = gerrit_connection(**kwargs)

    output, changed = update_account(
        gerrit_client, **{
            'username': username,
            'fullname': fullname,
            'email': email,
            'groups': groups,
        })

    return output


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
