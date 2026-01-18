import boto3
import json

def alter_admin_password_standard(cluster_id, database, admin_user, encoded_password):
    try:
        client = boto3.client('redshift-data')
        sql = f"ALTER USER {admin_user} PASSWORD 'sha256|{encoded_password}';"
        response = client.execute_statement(
            ClusterIdentifier=cluster_id,
            Database=database,
            DbUser=admin_user,
            Sql=sql
        )
        print(f"[Standard] Password updated for '{admin_user}' on cluster '{cluster_id}'.")
        return response

    except Exception as e:
        print(f"[Standard Error] {e}")
        raise

# INS-60052
# def alter_admin_password_serverless(workgroup_name, database, admin_user, encoded_password):
#     try:
#         client = boto3.client('redshift-data')
#         sql = f"ALTER USER {admin_user} PASSWORD 'sha256|{encoded_password}';"
#         response = client.execute_statement(
#             WorkgroupName=workgroup_name,
#             Database=database,
#             # DbUser=admin_user,
#             Sql=sql
#         )
#         print(f"[Serverless] Password updated for '{admin_user}' on workgroup '{workgroup_name}'.")
#         return response

#     except Exception as e:
#         print(f"[Serverless Error] {e}")
#         raise

def lambda_handler(event, context):
    try:
        producer_host = event.get("producer_host")
        producer_port = event.get("producer_port")
        producer_user = event.get("producer_user")
        producer_password = event.get("producer_password")
        producer_database = event.get("producer_database")
        producer_cluster_id = event.get("producer_cluster_id")
        # INS-60052
        # consumer_host = event.get("consumer_host")
        # consumer_port = event.get("consumer_port")
        # consumer_user = event.get("consumer_user")
        # consumer_password = event.get("consumer_password")
        # consumer_database = event.get("consumer_database")
        # consumer_workgroup = event.get("consumer_workgroup")

        alter_admin_password_standard(producer_cluster_id, producer_database, producer_user, producer_password)
        # INS-60052
        # alter_admin_password_serverless(consumer_workgroup, consumer_database, consumer_user, consumer_password)

        return {
            "statusCode": 200,
            "body": json.dumps({
                "message": "Admin password updated for Standard Redshift."
            })
        }

    except Exception as e:
        print(f"[Lambda Error] {e}")
        return {
            "statusCode": 500,
            "body": json.dumps({"error": str(e)})
        }
