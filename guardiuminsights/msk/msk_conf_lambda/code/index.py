import json
from kafka.admin import KafkaAdminClient, NewTopic, NewPartitions
from kafka.admin.acl_resource import ACLOperation, ResourcePatternFilter, ACLPermissionType, ACLFilter, ACL, ResourcePattern, ResourceType, ACLResourcePatternType

def lambda_handler(event, context):

    admin_client = KafkaAdminClient(
        bootstrap_servers=event['bootstrap_servers'],
        security_protocol="SSL"
    )

    resource_pattern = ResourcePattern(ResourceType.CLUSTER,'kafka-cluster', ACLResourcePatternType.LITERAL)
    resource_pattern_topic = ResourcePattern(ResourceType.TOPIC,'*', ACLResourcePatternType.LITERAL)
    resource_pattern_group = ResourcePattern(ResourceType.GROUP,'*', ACLResourcePatternType.LITERAL)

    acls = []
    acl1 = ACL(
                principal='User:kafka-admin',
                host='*',
                operation=ACLOperation.ALL,
                permission_type=ACLPermissionType.ALLOW,
                resource_pattern=resource_pattern
              )
    acl2 = ACL(
                principal='User:kafka-admin',
                host='*',
                operation=ACLOperation.ALL,
                permission_type=ACLPermissionType.ALLOW,
                resource_pattern=resource_pattern_topic
              )
    acl3 = ACL(
                principal='User:kafka-admin',
                host='*',
                operation=ACLOperation.ALL,
                permission_type=ACLPermissionType.ALLOW,
                resource_pattern=resource_pattern_group
              )

    acls.append(acl1)
    acls.append(acl2)
    acls.append(acl3)

    print(admin_client.create_acls(acls))

    admin_client.close()

    return {
        'statusCode': 200,
        'body': 'Done'
    }