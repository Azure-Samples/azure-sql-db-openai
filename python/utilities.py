import os
import pyodbc
import struct
import logging
from azure import identity

def get_mssql_connection():
    logging.info('Getting MSSQL connection')
    logging.info(' - Getting EntraID credentials...')    
    mssql_connection_string = os.environ["MSSQL"]    
    credential = identity.DefaultAzureCredential(exclude_interactive_browser_credential=False)    
    token_bytes = credential.get_token("https://database.windows.net/.default").token.encode("UTF-16-LE")    
    token_struct = struct.pack(f'<I{len(token_bytes)}s', len(token_bytes), token_bytes)
    SQL_COPT_SS_ACCESS_TOKEN = 1256  # This connection option is defined by microsoft in msodbcsql.h        
    logging.info(' - Connecting to MSSQL...')    
    conn = pyodbc.connect(mssql_connection_string, attrs_before={SQL_COPT_SS_ACCESS_TOKEN: token_struct})
    return conn