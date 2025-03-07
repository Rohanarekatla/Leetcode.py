import re
import smtplib
from datetime import datetime
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from collections import defaultdict

# Email configuration (Update these values)
SMTP_SERVER = 'smtp.office365.com'
SMTP_PORT = 587
EMAIL_ADDRESS = 'your_email@company.com'
EMAIL_PASSWORD = 'your_password'
TO_EMAILS = ['recipient1@company.com', 'recipient2@company.com']

def parse_input_data(input_file):
    # Same parsing function as previous answer
    accounts = []
    with open(input_file, 'r') as f:
        content = f.read()

    sections = re.split(r'SNOWFLAKE ACOUNT NAME\s*', content)[1:]
    
    for section in sections:
        account_data = defaultdict(str)
        url_match = re.search(r':\s*([\w\.-]+\.snowflakecomputing\.com)', section)
        account_data['Account URL'] = url_match.group(1).strip() if url_match else 'N/A'
        
        name_match = re.search(r'"ACCOUNT_?NAME["\']:\s*[\'*]([^\'"]+)[\'*]', section, re.IGNORECASE)
        account_data['Account Name'] = name_match.group(1).strip() if name_match else 'Unknown'
        
        kv_pairs = re.findall(r'["\']([^"\']+)["\']\s*:\s*["\']?([^"\']*)["\']?', section, re.DOTALL)
        
        for key, value in kv_pairs:
            clean_key = key.strip().replace('_', ' ').title()
            clean_value = value.strip().replace('•', '').replace('*', '').replace(',', ', ')
            if clean_key not in ['Account Name', 'Account URL']:
                account_data[clean_key] = clean_value
        
        accounts.append(dict(account_data))
    
    return accounts

def generate_html_content(accounts):
    # Same HTML generation as previous answer with dynamic columns
    css = """
    <style>
        /* Maintain the same CSS styles as previous answer */
        body { font-family: 'Arial', sans-serif; margin: 2em; }
        .report-title { color: #2c3e50; border-bottom: 2px solid #3498db; }
        /* ... rest of the CSS styles ... */
    </style>
    """
    
    # Generate HTML content (same as previous implementation)
    # ... [rest of HTML generation logic] ...
    
    return html_content

def send_email(html_content):
    # Create message container
    msg = MIMEMultipart('alternative')
    msg['Subject'] = f"Snowflake Account Report - {datetime.now().strftime('%Y-%m-%d')}"
    msg['From'] = EMAIL_ADDRESS
    msg['To'] = ", ".join(TO_EMAILS)

    # Create both HTML and plain-text versions
    text = "Please view this email in an HTML-compatible client."
    part1 = MIMEText(text, 'plain')
    part2 = MIMEText(html_content, 'html')

    # Attach parts to message
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
        print(f"Failed to send email: {str(e)}")

def main():
    input_file = "input.out"
    
    # Process data and generate HTML
    accounts = parse_input_data(input_file)
    columns = get_all_columns(accounts)
    html_content = generate_html(accounts, columns)
    
    # Send email directly
    send_email(html_content)

if __name__ == "__main__":
    main()