import os
from flask import Flask, request, jsonify
from werkzeug.utils import secure_filename

app = Flask(__name__)

# It's best practice to define where uploaded files will be temporarily saved
UPLOAD_FOLDER = './uploads'
os.makedirs(UPLOAD_FOLDER, exist_ok=True)
app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER

# Ensure we only accept image files
ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg'}

def allowed_file(filename):
    return '.' in filename and \
           filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS


@app.route('/info/', methods = ['GET'])
def info():
    return 'development only'


@app.route('/upload', methods=['POST'])
def upload_image():
    # 1. Check if the request contains the 'file' key
    # (This matches the attachmentKey="file" in your Swift code)
    if 'file' not in request.files:
        return jsonify({
            "status": "error",
            "message": "No file part in the request"
        }), 400

    file = request.files['file']

    # 2. Check if a file was actually selected
    if file.filename == '':
        return jsonify({
            "status": "error",
            "message": "No selected file"
        }), 400

    # 3. Process the file if it exists and has an allowed extension
    if file and allowed_file(file.filename):
        # Secure the filename to prevent directory traversal attacks
        filename = secure_filename(file.filename)
        
        # Save the file to disk (or you could pass it directly to an AI/CV model here)
        filepath = os.path.join(app.config['UPLOAD_FOLDER'], filename)
        file.save(filepath)

        # 4. Return a successful JSON response
        return jsonify({
            "status": "success",
            "message": "Image successfully received and processed",
            "data": {
                "filename": filename,
                "document_id": "doc_12345", # Simulated ID of the processed document
                "confidence_score": 0.98    # Simulated AI processing result
            }
        }), 200

    # If the file extension wasn't allowed
    return jsonify({
        "status": "error",
        "message": "File type not allowed. Please upload JPG or PNG."
    }), 400

if __name__ == '__main__':
    # Run the server on all available IP addresses on port 5000
    # This allows your physical iPhone to connect to it over local Wi-Fi
    app.run(host='0.0.0.0', port=5050, debug=True)
