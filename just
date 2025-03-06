import requests
from msrestazure.azure_active_directory import ServicePrincipalCredentials

def add_user_to_app_owners(tenant_id, app_display_name, user_upn, client_id, client_secret):
    # Auth
    credentials = ServicePrincipalCredentials(
        client_id=client_id,
        secret=client_secret,
        tenant=tenant_id,
        resource='https://graph.microsoft.com'
    )
    
    headers = {
        'Authorization': f'Bearer {credentials.token["access_token"]}',
        'Content-Type': 'application/json'
    }
    
    # Find app by display name
    app_response = requests.get(
        f'https://graph.microsoft.com/v1.0/servicePrincipals?$filter=displayName eq \'{app_display_name}\'', 
        headers=headers
    )
    app_id = app_response.json()['value'][0]['id']
    
    # Find user by UPN
    user_response = requests.get(f'https://graph.microsoft.com/v1.0/users/{user_upn}', headers=headers)
    user_id = user_response.json()['id']
    
    # Add user as owner
    return requests.post(
        f'https://graph.microsoft.com/v1.0/servicePrincipals/{app_id}/owners/$ref',
        headers=headers,
        json={"@odata.id": f"https://graph.microsoft.com/v1.0/users/{user_id}"}
    ).status_code == 204

if __name__ == "__main__":
    add_user_to_app_owners(
        tenant_id="your-tenant-id",
        app_display_name="App Name",
        user_upn="user@domain.com",
        client_id="your-client-id",
        client_secret="your-client-secret"
    )