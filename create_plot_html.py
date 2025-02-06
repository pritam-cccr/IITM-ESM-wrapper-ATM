# ==============================================================================
#  Copyright (C) 2025 Centre for Climate Change Research (CCCR), IITM
#
#  This script is part of the CCCR IITM_ESM diagnostics system.
#
#  Author: Praveen V; Pritam Das Mahapatra
#  Date: January 2025
#  Version: 1.3
#
# ==============================================================================

import sys
import os
from weasyprint import HTML, CSS

if len(sys.argv) != 3:
    print("Usage: python create_plot_html.py <image_details_file> <output_html_file>")
    sys.exit(1)

#============================================================
imglistfile = sys.argv[1]
outhtmlfile = sys.argv[2]
outpdf_file = outhtmlfile.replace(".html", ".pdf")  # Generate PDF filename

#============================================================
# HTML Generation with Captions
html_content = """<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Plots</title>
    <style>
        body {
            font-family: Arial, sans-serif;
        }
        ul {
            list-style-type: none;
            padding: 0;
        }
        li {
            display: flex;
            align-items: center;
            margin-bottom: 20px;
        }
        img {
            max-width: 600px;
            max-height: 600px;
            margin-right: 20px;
        }
        .caption {
            font-size: 18px; 
            color: #333;
            text-decoration: none;
        }
    </style>
</head>
<body>
    <h1>Plots</h1>
    <ul>
"""

# Read image details file
with open(imglistfile, 'r') as file:
    lines = file.readlines()

# Process images for HTML (Pairs: Image File + Caption)
for i in range(0, len(lines) - 1, 2):
    img_file = lines[i].strip()
    caption = lines[i + 1].strip()

    html_content += f'  <li><a href="{img_file}"><img src="{img_file}" alt="{caption}"></a> <a href="{img_file}" class="caption">{caption}</a></li>\n'

html_content += """
    </ul>
</body>
</html>
"""

# Save HTML output with captions
with open(outhtmlfile, 'w') as file:
    file.write(html_content)

print(f"✅ HTML file created: {outhtmlfile}")

#============================================================
# PDF Generation (One Image Per A4 Page, Caption from Filename)
#============================================================
pdf_html_content = """<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Plots (PDF Version)</title>
    <style>
        @page {
            size: A4 portrait;
            margin: 20px;
        }
        body {
            font-family: Arial, sans-serif;
            text-align: center;
        }
        .caption {
            font-size: 16px;
            font-weight: bold;
            margin-bottom: 10px;
        }
        img {
            max-width: 100%;
            max-height: 100%;
            display: block;
            margin: auto;
        }
    </style>
</head>
<body>
"""

# Process images for PDF (one per page, caption from filename without extension)
for i in range(0, len(lines) - 1, 2):
    img_file = lines[i].strip()
    img_filename = os.path.splitext(os.path.basename(img_file))[0]  # **Fix: Remove file extension**

    pdf_html_content += f'<div style="page-break-after: always;">'
    pdf_html_content += f'<div class="caption">{img_filename}</div>'  # Caption without extension
    pdf_html_content += f'<img src="{img_file}" alt="Plot"></div>\n'

pdf_html_content += """
</body>
</html>
"""

# Temporary HTML file for PDF generation
temp_pdf_html = "temp_pdf_generation.html"
with open(temp_pdf_html, 'w') as file:
    file.write(pdf_html_content)

# Convert temporary HTML to PDF
try:
    HTML(temp_pdf_html).write_pdf(outpdf_file)
    print(f"✅ PDF file created (each image on a separate page with filename as caption): {outpdf_file}")
    os.remove(temp_pdf_html)  # Clean up temporary HTML file
except Exception as e:
    print(f"❌ Error generating PDF: {e}")

