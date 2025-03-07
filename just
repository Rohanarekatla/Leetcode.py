import re
import os
import smtplib
from datetime import datetime
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from email.mime.application import MIMEApplication

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
    <html lang="en">
    <head>
        <!-- Same HTML/CS structure as before -->
    </head>
    <body>
        <div class="report-container">
            <div class="report-header">
                Snowflake Account Configuration Report
            </div>
            <div class="report-date">
                Report Date: {datetime.now().strftime("%A, %B %d, %Y")}
            </div>
    """
    
    for account in accounts:
        html += f"""
            <div class="account-section">
                <div class="account-name">
                    SNOWFLAKE ACCOUNT: <span style="color: #0066b2;">{account['url']}</span>
                </div>
                <table>
                    <tr><th>Configuration</th><th>Value</th></tr>
        """
        for key, value in account['details'].items():
            if key == "omgomgsws_SP": continue
            html += f"""<tr><td>{key}</td><td>{value}</td></tr>"""
        html += """</table></div>"""
    
    html += """</div></body></html>"""
    return html

def send_email_smtp(smtp_host, smtp_port, smtp_user, smtp_pass, from_addr, to_addrs, subject, html_body, attachment_path=None):
    """Send email via SMTP server with HTML content and optional attachment"""
    try:
        msg = MIMEMultipart()
        msg['From'] = from_addr
        msg['To'] = ', '.join(to_addrs.split(';'))
        msg['Subject'] = subject

        # Attach HTML body
        msg.attach(MIMEText(html_body, 'html'))

        # Attach file if specified
        if attachment_path and os.path.exists(attachment_path):
            with open(attachment_path, "rb") as f:
                part = MIMEApplication(f.read(), Name=os.path.basename(attachment_path))
            part['Content-Disposition'] = f'attachment; filename="{os.path.basename(attachment_path)}"'
            msg.attach(part)

        # Connect to server
        if smtp_port == 465:
            server = smtplib.SMTP_SSL(smtp_host, smtp_port)
        else:
            server = smtplib.SMTP(smtp_host, smtp_port)
            server.starttls()

        server.login(smtp_user, smtp_pass)
        server.sendmail(from_addr, [addr.strip() for addr in to_addrs.split(';')], msg.as_string())
        server.quit()
        print("Email sent successfully!")
        return True
    except Exception as e:
        print(f"Error sending email: {str(e)}")
        return False

def main():
    # Configuration
    config_file_path = "snowflake_config.out"
    email_recipients = "recipient1@example.com;recipient2@example.com"
    email_subject = f"Snowflake Account Configuration Report - {datetime.now().strftime('%Y-%m-%d')}"
    
    # SMTP Configuration (Update these values)
    SMTP_HOST = 'smtp.example.com'
    SMTP_PORT = 587
    SMTP_USER = 'your_email@example.com'
    SMTP_PASS = 'your_password'
    FROM_ADDR = 'your_email@example.com'

    # File processing
    content = read_config_file(config_file_path)
    if not content: return

    accounts = parse_snowflake_data(content)
    if not accounts: return

    html_report = generate_html_report(accounts)
    
    # Save report
    html_file_path = f"snowflake_report_{datetime.now().strftime('%Y%m%d')}.html"
    with open(html_file_path, 'w') as f:
        f.write(html_report)

    # Send email
    sent = send_email_smtp(
        SMTP_HOST, SMTP_PORT, SMTP_USER, SMTP_PASS,
        FROM_ADDR, email_recipients, email_subject,
        html_report, html_file_path
    )
    
    if sent:
        print("Process completed successfully.")
    else:
        print("Failed to send email.")

if __name__ == "__main__":
    main()