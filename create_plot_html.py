# Praveen V
import sys
import os

if len(sys.argv) != 3:
    print("Usage: python create_plot_html.py <image_details_file> <output_html_file>")
    sys.exit(1)

#============================================================
imglistfile = sys.argv[1]
outhtmlfile = sys.argv[2]

#============================================================
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
            max-width: 400px;
            max-height: 400px;
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

# Open the text file in read mode
with open(imglistfile, 'r') as file:
    lines = file.readlines()

# Process the image list in pairs (image file and caption)
for i in range(0, len(lines) - 1, 2):
    img_file = lines[i].strip()
    caption = lines[i + 1].strip()

    print(f"Image file: {img_file}")
    print(f"Caption: {caption}")

    html_content += f'  <li><a href="{img_file}"><img src="{img_file}" alt="{caption}"></a> <a href="{img_file}" class="caption">{caption}</a></li>\n'

html_content += """
    </ul>
</body>
</html>
"""

# Write the HTML output
with open(outhtmlfile, 'w') as file:
    file.write(html_content)

print(f"HTML file created: {outhtmlfile}")

