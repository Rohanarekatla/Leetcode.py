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
    
    for account_url in account_sections:
        section_pattern = f'SNOWFLAKE ACCOUNT NAME\\s+:\\s+{re.escape(account_url)}([\\s\\S]+?)(?=SNOWFLAKE ACCOUNT NAME|$)'
        section_match = re.search(section_pattern, content)
        
        if not section_match:
            continue
            
        section = section_match.group(1)
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
    """Generate HTML email content with properly formatted tables"""
    html = f"""<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Snowflake Configuration Report</title>
</head>
<body style="font-family: Arial, sans-serif; margin: 20px; color: #333;">
    <div style="max-width: 1000px; margin: 0 auto;">
        <h2 style="color: #0066b2; border-bottom: 2px solid #eee; padding-bottom: 10px;">
            Snowflake Account Configuration Report
        </h2>
        <p style="color: #666; font-size: 0.9em;">
            Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}
        </p>"""
    
    for account in accounts:
        html += f"""
        <div style="margin: 30px 0; padding: 20px; background: #f8f9fa; border-radius: 5px;">
            <h3 style="color: #444; margin-top: 0;">
                Account: <span style="color: #0066b2;">{account['url']}</span>
            </h3>
            <table style="width: 100%; border-collapse: collapse; background: white;">
                <thead>
                    <tr style="background-color: #0066b2; color: white;">
                        <th style="padding: 12px; border: 1px solid #ddd; text-align: left;">Configuration</th>
                        <th style="padding: 12px; border: 1px solid #ddd; text-align: left;">Value</th>
                    </tr>
                </thead>
                <tbody>"""
        
        for key, value in account['details'].items():
            if key == "omgomgsws_SP":
                continue
            html += f"""
                    <tr>
                        <td style="padding: 12px; border: 1px solid #ddd; vertical-align: top; width: 40%;">{key}</td>
                        <td style="padding: 12px; border: 1px solid #ddd; vertical-align: top;">{value}</td>
                    </tr>"""
        
        html += """
                </tbody>
            </table>
        </div>"""
    
    html += """
    </div>
</body>
</html>"""
    
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
    email_recipients = ["recipient@example.com"]  # List of recipient emails
    email_subject = f"Snowflake Configuration Report - {datetime.now().strftime('%Y-%m-%d')}"
    
    # SMTP Configuration (Update these values)
    SMTP_HOST = 'your-smtp-server.com'  # e.g., 'smtp.corporate.com'
    SMTP_PORT = 25                      # Common ports: 25, 587
    FROM_ADDR = 'reports@example.com'   # Sender email address

    # Process the config file
    content = read_config_file(config_file_path)
    if not content:
        print("Failed to read config file")
        return

    accounts = parse_snowflake_data(content)
    if not accounts:
        print("No account data found")
        return

    # Generate HTML report
    html_report = generate_html_report(accounts)
    
    # Optional: Save report for debugging
    with open("latest_report.html", "w") as f:
        f.write(html_report)
    
    # Send email
    success = send_email_smtp(
        SMTP_HOST,
        SMTP_PORT,
        FROM_ADDR,
        email_recipients,
        email_subject,
        html_report
    )
    
    if success:
        print("Report generated and sent successfully")
    else:
        print("Failed to send report")

if __name__ == "__main__":
    main()