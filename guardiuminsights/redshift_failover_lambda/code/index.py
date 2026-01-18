import os
import json
#import time
import redshift_connector
#import subprocess
#import sys
import boto3



def create_datashare_on_redshift_producer(producer_host,producer_port,producer_user,producer_password,producer_database,datashare_name):
    try:
        # Connect to producer cluster
        conn = redshift_connector.connect(
            host=producer_host,
            database=producer_database,
            port=producer_port,
            user=producer_user,
            password=producer_password,
            ssl=True
        )
        cursor = conn.cursor()
        conn.autocommit= True
        
        # Create datashare
        create_datashare =f"""
            CREATE DATASHARE {datashare_name};
            """
        add_schema =f"""
            GRANT USAGE, CREATE, DROP, ALTER FOR SCHEMAS IN DATABASE {producer_database} TO DATASHARE {datashare_name};
            """
        add_table =f"""
            GRANT INSERT, SELECT, UPDATE, DELETE, REFERENCES, DROP, TRUNCATE, ALTER FOR TABLES IN DATABASE {producer_database} TO DATASHARE {datashare_name};
            """
        add_function =f"""
            GRANT EXECUTE FOR FUNCTIONS IN DATABASE {producer_database} TO DATASHARE {datashare_name};
            """
        cursor.execute(create_datashare)
        print(f"created Datashare : {datashare_name}")
        cursor.execute(add_schema)
        print(f"All the schemas are added in the datashare")
        cursor.execute(add_table)
        print(f"all the tables are added in the datashare")
        cursor.execute(add_function)
        print(f"All the function are added in the datashare")
        conn.autocommit= False
        cursor.close()
        conn.close()
    except Exception as e:
        print(f"Datashare creation has failed: {e}")

#2. Associate datashare with the consumer namespace 
def associate_datashare_to_redshift_consumer(producer_host,producer_port,producer_user,producer_password,producer_database,datashare_name,consumer_namespace_id):
    try:
        # Connect to producer cluster
        conn = redshift_connector.connect(
            host=producer_host,
            database=producer_database,
            port=producer_port,
            user=producer_user,
            password=producer_password,
            ssl=True
        )
        cursor = conn.cursor()
        conn.autocommit= True
        
        # associate datashare with the consumer redshift namespace
        associate_datashare =f"""
            GRANT USAGE ON DATASHARE {datashare_name} TO NAMESPACE {consumer_namespace_id};
            """
        cursor.execute(associate_datashare)
        print(f"Datashare {datashare_name} is associated with consumer namespace {consumer_namespace_id}")
        conn.autocommit= False
        cursor.close()
        conn.close()
    except Exception as e:
        print(f"Datashare association with the consumer redshift is failing: {e}")

# 3. Create external Datatabase on the consumer for the producer datashare

def create_consumer_external_db(consumer_host,consumer_port,consumer_user,consumer_password,consumer_database,datashare_name,producer_account_id,producer_namespace_id,external_db):
    try:
        conn = redshift_connector.connect(
            host=consumer_host,
            database=consumer_database,
            port=consumer_port,
            user=consumer_user,
            password=consumer_password,
            ssl=True
            #ssl={'ca': ssl_cert_path}
        )
        cursor = conn.cursor()
        conn.autocommit= True
        
        # Create datashare
        consumer_datashare =f"""
            CREATE DATABASE {external_db} FROM DATASHARE {datashare_name} OF ACCOUNT '{producer_account_id}' NAMESPACE '{producer_namespace_id}';
            """
        cursor.execute(consumer_datashare)
        print(f"external DB {external_db} is created on the consumer successfully on the datashare {datashare_name}")
        conn.autocommit= False
        cursor.close()
        conn.close()
    except Exception as e:
        print(f"external DB creation on the consumer redshift is failing: {e}")



def lambda_handler(event, context):
    try:
        producer_host = event.get("producer_host")
        producer_port = event.get("producer_port")
        producer_user = event.get("producer_user")
        producer_password = event.get("producer_password")
        producer_database = event.get("producer_database")
        datashare_name = event.get("datashare_name")
        consumer_namespace_id = event.get("consumer_namespace_id")
        consumer_host = event.get("consumer_host")
        consumer_port = event.get("consumer_port")
        consumer_user = event.get("consumer_user")
        consumer_password = event.get("consumer_password")
        consumer_database = event.get("consumer_database")
        producer_account_id = event.get("producer_account_id")
        producer_namespace_id = event.get("producer_namespace_id")
        external_db = event.get("external_db")
        
        # SSL cert path
        ssl_cert_path = 'files/SFSRootCAG2.pem'
        os.environ['SSL_CERT_FILE'] = ssl_cert_path

        # 1. Create datashare on the producer redshift cluster 
        create_datashare_on_redshift_producer(producer_host,producer_port,producer_user,producer_password,producer_database,datashare_name)
        
        # 2. Associate datahshare with the consumer redshift namespace
        associate_datashare_to_redshift_consumer(producer_host,producer_port,producer_user,producer_password,producer_database,datashare_name,consumer_namespace_id)
        
        # 3. Create external DB on the consumer redshift for the producer datashare
        create_consumer_external_db(consumer_host,consumer_port,consumer_user,consumer_password,consumer_database,datashare_name,producer_account_id,producer_namespace_id,external_db)
        
    except Exception as e:
        print(f"Transactional Message: {e}")
    return {
        'statusCode': 200,
        'body': json.dumps('[INFO] Successfully created datashare.')
    }