import re
import smtplib
from datetime import datetime
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText

def read_config_file(file_path):
    """Read and parse the .out config file"""
    try:
        with open(file_path, 'r') as file:
            content = file.read()
        return content
    except Exception as e:
        print(f"Error reading file: {e}")
        return None

def parse_snowflake_data(content):
    """Parse the Snowflake account data from the file content"""
    accounts = []
    pattern = r'SNOWFLAKE ACCOUNT NAME\s+:\s+([\w\.]+\.snowflakecomputing\.com)[\s\S]+?(?=SNOWFLAKE ACCOUNT NAME|$)'
    account_sections = re.findall(pattern, content)
    
    for i, account_url in enumerate(account_sections):
        if i < len(account_sections) - 1:
            section = re.search(f'SNOWFLAKE ACCOUNT NAME\s+:\s+{re.escape(account_url)}[\\s\\S]+?(?=SNOWFLAKE ACCOUNT NAME)', content).group(0)
        else:
            section = re.search(f'SNOWFLAKE ACCOUNT NAME\s+:\s+{re.escape(account_url)}[\\s\\S]+', content).group(0)
        
        account_data = {'url': account_url, 'details': {}}
        fields = {
            'ACCOUNT_NAME': r"'ACCOUNT_NAME':\s+'([^']+)'",
            'PERIODIC_DATA_REKEYING': r"'PERIODIC_DATA_REKEYING':\s+'([^']+)'",
            'DAYS_RETENTION': r"'DAYS_RETENTION':\s+'([^']+)'",
            'DATABASES_NOT_IN_REPLICATION': r"'DATABASES_NOT_IN_REPLICATION':\s+'([^']+)'",
            'RESOURCE_MONITORS>75%': r"'RESOURCE_MONITORS>75%':\s+'([^']+)'",
            'WAREHOUSES_WITHOUT_RM': r"'WAREHOUSES_WITHOUT_RM':\s+'([^']+)'",
            'USERNAMES_WITHOUT_NP': r"'USERNAMES_WITHOUT_NP':\s+'([^']+)'",
            'DATABASE_BACKUPS': r"'DATABASE_BACKUPS':\s+'([^']+)'",
            'ABNORMAL_WAREHOUSES': r"'ABNORMAL_WAREHOUSES':\s+'([^']+)'",
            'TASK_STATUS': r"'TASK_STATUS':\s+'([^']+)'"
        }
        
        for key, pattern in fields.items():
            match = re.search(pattern, section)
            if match:
                account_data['details'][key] = match.group(1)
        
        accounts.append(account_data)
    
    return accounts

def generate_html_report(accounts):
    """Generate HTML email content from the parsed account data"""
    html = f"""
    <!DOCTYPE html>
    <html>
    <head>
        <style>
            body {{ font-family: Arial, sans-serif; margin: 20px; }}
            .report-container {{ border: 1px solid #ddd; padding: 20px; }}
            .account-section {{ margin-bottom: 30px; }}
            table {{ width: 100%; border-collapse: collapse; margin-top: 10px; }}
            th, td {{ padding: 10px; text-align: left; border-bottom: 1px solid #ddd; }}
            th {{ background-color: #f5f5f5; }}
        </style>
    </head>
    <body>
        <div class="report-container">
            <h2>Snowflake Configuration Report</h2>
            <p>Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}</p>
    """
    
    for account in accounts:
        html += f"""
            <div class="account-section">
                <h3>{account['url']}</h3>
                <table>
                    <tr><th>Configuration</th><th>Value</th></tr>
        """
        for key, value in account['details'].items():
            if key == "omgomgsws_SP": continue
            html += f"<tr><td>{key}</td><td>{value}</td></tr>"
        html += "</table></div>"
    
    html += "</div></body></html>"
    return html

def send_email_smtp(smtp_host, smtp_port, from_addr, to_addrs, subject, html_body):
    """Send email via SMTP server without authentication"""
    try:
        msg = MIMEMultipart()
        msg['From'] = from_addr
        msg['To'] = ', '.join(to_addrs)
        msg['Subject'] = subject
        msg.attach(MIMEText(html_body, 'html'))

        with smtplib.SMTP(smtp_host, smtp_port) as server:
            server.sendmail(from_addr, to_addrs, msg.as_string())
        
        print("Email sent successfully!")
        return True
    except Exception as e:
        print(f"Error sending email: {str(e)}")
        return False

def main():
    # Configuration
    config_file_path = "snowflake_config.out"
    email_recipients = ["recipient@example.com"]  # List of recipients
    email_subject = f"Snowflake Report - {datetime.now().strftime('%Y-%m-%d')}"
    
    # SMTP Configuration (Update these for your environment)
    SMTP_HOST = 'your.smtp.server.com'  # e.g., 'smtp.corporate.com'
    SMTP_PORT = 25                      # Common ports: 25, 587
    FROM_ADDR = 'noreply@example.com'    # Sender email address

    # Process report
    content = read_config_file(config_file_path)
    if not content: return

    accounts = parse_snowflake_data(content)
    if not accounts: return

    html_report = generate_html_report(accounts)
    
    # Send email
    sent = send_email_smtp(
        SMTP_HOST,
        SMTP_PORT,
        FROM_ADDR,
        email_recipients,
        email_subject,
        html_report
    )
    
    if sent:
        print("Process completed successfully.")
    else:
        print("Failed to send email.")

if __name__ == "__main__":
    main()