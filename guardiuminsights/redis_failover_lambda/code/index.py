import json
import time

import boto3

session = boto3.Session()
client = session.client('elasticache')


def lambda_handler(event, context):
    try:
        print("[INFO] Validating the inputs...")
        validate_input(event)
        print("[INFO] Successfully validated the inputs...")
        global_replication_group_id = event.get("global_replication_group_id")
        replication_group_id = event.get("replication_group_id")
        replication_group_region = event.get("replication_group_region")
        print(f"[INFO] GlobalReplicationGroupId: {global_replication_group_id}")
        print(f"[INFO] ReplicationGroupId: {replication_group_id}")
        print(f"[INFO] ReplicationGroupRegion: {replication_group_region}")
        print(f"[INFO] Started the process to remove the secondary cluster '{replication_group_id}' from the global datastore '{global_replication_group_id}'.")
        disassociate_global_replication_group(global_replication_group_id, replication_group_id, replication_group_region)
        print(f"[INFO] Started process to remove the secondary cluster '{replication_group_id}' from the global datastore '{global_replication_group_id}' and promote it to a standalone cluster in '{replication_group_region}' with read/write capability.")
        print(f"[INFO] Modifying cluster '{replication_group_id}' role...")
        time.sleep(180)
        replication_group_status = get_replication_group_status(replication_group_id)
        while replication_group_status != 'available':
            print(f"[INFO] Waiting for the cluster '{replication_group_id}' to be available. Current cluster status: '{replication_group_status}'. Checking cluster status again in 10 seconds...")
            time.sleep(10)
            replication_group_status = get_replication_group_status(replication_group_id)
        print(f"[INFO] Cluster '{replication_group_id}' is now {replication_group_status}.")
        print(f"[INFO] Successfully removed the secondary cluster '{replication_group_id}' from the global datastore '{global_replication_group_id}' and promoted it to a standalone cluster in '{replication_group_region}' with read/write capability.")
    except RuntimeError as error:
        raise error
    return {
        'statusCode': 200,
        'body': json.dumps('[INFO] Successfully removed the secondary cluster from the global datastore and promoted it to a standalone cluster with read/write capability.')
    }

def disassociate_global_replication_group(global_replication_group_id, replication_group_id, replication_group_region):
    try:
        response = client.disassociate_global_replication_group(
            GlobalReplicationGroupId=global_replication_group_id,
            ReplicationGroupId=replication_group_id,
            ReplicationGroupRegion=replication_group_region
        )
    except Exception as error:
        raise error

def get_replication_group_status(replication_group_id):
    try:
        response = client.describe_replication_groups(
            ReplicationGroupId=replication_group_id,
        )
        return response['ReplicationGroups'][0]['Status']
    except Exception as error:
        raise error

def validate_input(event):
    try:
        if not event["global_replication_group_id"]:
            print("Please provide a valid global replication group id.")
            raise RuntimeError("Please provide a valid global replication group id.")
        if not event["replication_group_id"]:
            print("Please provide a valid replication group id.")
            raise RuntimeError("Please provide a valid replication group id.")
        if not event["replication_group_region"]:
            print("Please provide replication group Region.")
            raise RuntimeError("Please provide replication group Region.")
    except KeyError as error:
        raise error
