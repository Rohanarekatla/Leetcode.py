import re
import smtplib
from datetime import datetime
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from collections import defaultdict

# Configuration - Update these values before use
SMTP_SERVER = 'smtp.office365.com'
SMTP_PORT = 587
EMAIL_ADDRESS = 'your_email@company.com'  # Replace with your email
EMAIL_PASSWORD = 'your_password'         # Replace with your password
TO_EMAILS = ['recipient1@company.com', 'recipient2@company.com']  # Recipient list
INPUT_FILE = 'input.out'  # Path to your input file

def parse_input_data(input_file):
    accounts = []
    
    with open(input_file, 'r') as f:
        content = f.read()

    sections = re.split(r'SNOWFLAKE ACOUNT NAME\s*', content)[1:]
    
    for section in sections:
        account_data = defaultdict(str)
        
        # Extract account URL
        url_match = re.search(r':\s*([\w\.-]+\.snowflakecomputing\.com)', section)
        account_data['Account URL'] = url_match.group(1).strip() if url_match else 'N/A'
        
        # Extract account name
        name_match = re.search(r'"ACCOUNT_?NAME["\']:\s*[\'*]([^\'"]+)[\'*]', section, re.IGNORECASE)
        account_data['Account Name'] = name_match.group(1).strip() if name_match else 'Unknown'
        
        # Extract all key-value pairs
        kv_pairs = re.findall(
            r'["\']([^"\']+)["\']\s*:\s*["\']?([^"\']*)["\']?',
            section,
            re.DOTALL
        )
        
        # Process key-value pairs
        for key, value in kv_pairs:
            clean_key = key.strip().replace('_', ' ').title()
            clean_value = value.strip().replace('•', '').replace('*', '').replace(',', ', ')
            if clean_key not in ['Account Name', 'Account URL']:
                account_data[clean_key] = clean_value
        
        accounts.append(dict(account_data))
    
    return accounts

def get_all_columns(accounts):
    columns = set()
    for account in accounts:
        columns.update(account.keys())
    return sorted(columns - {'Account Name', 'Account URL'})

def generate_html_content(accounts):
    # Get all columns and prioritize important ones
    columns = get_all_columns(accounts)
    priority_columns = ['Resource Monitors>75', 'Abnormal Warehouses', 'Task Status']
    columns = sorted(set(columns) - set(priority_columns), key=lambda x: x.lower())
    columns = priority_columns + columns

    css = """
    <style>
        body { 
            font-family: 'Segoe UI', Arial, sans-serif; 
            margin: 40px; 
            background-color: #f5f6fa;
        }
        .report-title {
            color: #2c3e50;
            border-bottom: 3px solid #3498db;
            padding-bottom: 15px;
            margin-bottom: 30px;
        }
        .account-section {
            background: white;
            border-radius: 10px;
            box-shadow: 0 2px 15px rgba(0,0,0,0.1);
            margin-bottom: 30px;
            padding: 25px;
        }
        .account-name {
            color: #2980b9;
            font-size: 1.4em;
            margin-bottom: 20px;
            font-weight: 600;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin: 20px 0;
        }
        th, td {
            padding: 15px;
            text-align: left;
            border-bottom: 1px solid #ecf0f1;
        }
        th {
            background-color: #3498db;
            color: white;
            font-weight: 600;
        }
        tr:nth-child(even) { background-color: #f8f9fa; }
        .alert {
            color: #e74c3c;
            font-weight: bold;
        }
        .timestamp {
            color: #7f8c8d;
            margin-bottom: 25px;
            font-size: 0.95em;
        }
        .account-url {
            color: #3498db;
            font-weight: 500;
        }
    </style>
    """

    html_content = f"""
    <!DOCTYPE html>
    <html>
    <head>
        <title>Snowflake Account Report</title>
        {css}
    </head>
    <body>
        <h1 class="report-title">❄️ Daily Snowflake Account Health Report</h1>
        <div class="timestamp">Generated: {datetime.now().strftime('%Y-%m-%d %H:%M')}</div>
    """

    for account in accounts:
        html_content += f"""
        <div class="account-section">
            <div class="account-name">🔷 {account['Account Name']}</div>
            <div class="account-url">🌐 {account['Account URL']}</div>
            <table>
                <tr>
                    {''.join(f'<th>{col}</th>' for col in columns)}
                </tr>
                <tr>
                    {''.join(
                        f'<td class="alert">⚠️ {account[col]}</td>' if "NA" in str(account.get(col, '')).upper() 
                        else f'<td>{account.get(col, "-")}</td>' 
                        for col in columns
                    )}
                </tr>
            </table>
        </div>
        """

    html_content += "</body></html>"
    return html_content

def send_email(html_content):
    # Create email message
    msg = MIMEMultipart('alternative')
    msg['Subject'] = f"Snowflake Account Report - {datetime.now().strftime('%Y-%m-%d')}"
    msg['From'] = EMAIL_ADDRESS
    msg['To'] = ", ".join(TO_EMAILS)

    # Create both HTML and plain text versions
    text = "Please view this email in an HTML-compatible email client."
    part1 = MIMEText(text, 'plain')
    part2 = MIMEText(html_content, 'html')

    msg.attach(part1)
    msg.attach(part2)

    # Send email
    try:
        with smtplib.SMTP(SMTP_SERVER, SMTP_PORT) as server:
            server.starttls()
            server.login(EMAIL_ADDRESS, EMAIL_PASSWORD)
            server.sendmail(EMAIL_ADDRESS, TO_EMAILS, msg.as_string())
        print("Email sent successfully!")
    except Exception as e:
        print(f"Error sending email: {str(e)}")

def main():
    # Parse input data
    accounts = parse_input_data(INPUT_FILE)
    
    # Generate HTML content
    html_content = generate_html_content(accounts)
    
    # Send email
    send_email(html_content)

if __name__ == "__main__":
    main()