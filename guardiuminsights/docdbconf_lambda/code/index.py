import sys
import pymongo

def docdb_connect(credentials):
    try:
        conn = pymongo.MongoClient('mongodb://%s:%s@%s:%s/?tls=true&tlsCAFile=files/global-bundle.pem&replicaSet=rs0&readPreference=secondaryPreferred&retryWrites=false' % (credentials['user'], credentials['password'], credentials['host'], credentials['port']))
        msg = 'Connection to DocDB established'
    except Exception as e:
        conn = None
        msg = str(e)
    return conn, msg


def create_user(conn, user):
    try:
        conn.admin.command('createUser', user['user'], pwd=user['pwd'], roles=user['roles'])
    except Exception as e:
        return str(e)
    return 'User %s created' % user['user']

def lambda_handler(event, context):
    messages = list()
    conn, msg = docdb_connect(event.get('docdb_credentials'))
    messages.append(('Info: %s' % msg))
    if conn:
        if event.get('action') == 'createUser':
           for user in event.get('users'):
               messages.append('Info: %s' % (create_user(conn, user)))
        else:
            messages.append('Error: Undefined action: %s' % event.get('action'))
        conn.close()
    return messages
